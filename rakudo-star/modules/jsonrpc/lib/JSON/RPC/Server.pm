use JSON::Tiny;
use JSON::RPC::Error;

class JSON::RPC::Server;

# debug attributes
has Bool $.debug = False;
has %.history is rw;

# application to dispatch requests to
has Any $.application is rw = Any.new;

method run ( Str :$host = '', Int :$port = 8080 ) {

    # listen on given host/port
    my $listener = IO::Socket::INET.new( localhost => $host, localport => $port, :listen );

    say 'Listening on ' ~ $host ~ ':' ~ $port if $.debug;

    # new client connected
    while my $connection = $listener.accept( ) {

        # process status line
        my ( $method, $uri, $protocol ) = $connection.get( ).comb( /\S+/ );

        my $body;
        loop {
            my $line = $connection.get( );

            # line that ends header section
            last if $line ~~ "\x0D";

            # for now another headers are ignored
            # they will be parsed properly after switch to HTTP::Transport
            next unless $line ~~ m:i/^ 'Content-Length:' <ws> (\d+) /;

            # store body length
            $body = $/[0];
        }

        # RFC 2616
        # For compatibility with HTTP/1.0 applications, HTTP/1.1 requests
        # containing a message-body MUST include a valid Content-Length header
        # field unless the server is known to be HTTP/1.1 compliant. If a
        # request contains a message-body and a Content-Length is not given,
        # the server SHOULD respond with 400 (bad request) if it cannot
        # determine the length of the message...

        unless $body {
            my $response = $protocol ~ ' 400 Bad Request' ~ "\x0D\x0A" ~ "\x0D\x0A";
            $connection.send( $response );
            $connection.close( );
            next;
        }

        # receive message body 
        $body = $connection.read( $body ).decode( );

        # dispatch remote procedure call
        my $response = self.handler( json => $body );

        # wrap response in HTTP Response
        $response = $protocol ~ ' 200 OK' ~ "\x0D\x0A"
            ~ 'Content-Type: application/json' ~ "\x0D\x0A"
            ~ 'Content-Length: ' ~ $response.encode( 'UTF-8' ).bytes ~ "\x0D\x0A"
            ~ "\x0D\x0A"
            ~ $response;

        # send response to client
        $connection.send( $response );

        # close connection with client, no keep-alive yet
        $connection.close( );   
    }

}

method handler ( Str :$json! ) {

    # container for response
    my %response = (
        # A String specifying the version of the JSON-RPC protocol.
        # MUST be exactly "2.0".
        'jsonrpc' => '2.0',
    );

    try {
        my %parsed      = self.parse_json( $json );
        my $version     = self.validate_request( |%parsed );
        my $method      = self.search_method( %parsed{'method'} );
        my $candidate   = self.validate_params( $method, %parsed{'params'} );

        # This member is REQUIRED on success.
        %response{'result'} = self.call( $candidate, %parsed{'params'} );

        # This member is REQUIRED on success.
        # It MUST be the same as the value of the id member in the Request Object.
        %response{'id'} = %parsed{'id'};

        CATCH {

            when JSON::RPC::ParseError|JSON::RPC::InvalidRequest {

                # This member is REQUIRED on error.
                %response{'error'} = .Hash;

                # This member is REQUIRED.
                # If there was an error in detecting the id in the Request object, it MUST be Null.
                %response{'id'} = Any;

            }

            when JSON::RPC::Error {

                # This member is REQUIRED on error.
                %response{'error'} = .Hash;


                # This member is REQUIRED.
                # It MUST be the same as the value of the id member in the Request Object.
                %response{'id'} = %parsed{'id'};

            }

            # do not use default handler
            # propagate unhandled exception to parent scope
        }
    };

    # in debug mode save last generated response
    %.history = %response if $.debug;

    return to-json( %response );
}

method parse_json ( Str $body ) {

    my %parsed;

    try { %parsed = from-json( $body ); };

    JSON::RPC::ParseError.new( data => ~$! ).throw if defined $!;

    return %parsed;
}

multi method validate_request (

    # A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
    Str :$jsonrpc! where '2.0',

    # A String containing the name of the method to be invoked.
    # Method names that begin with the word rpc followed by a period character
    # are reserved for rpc-internal methods and extensions
    # and MUST NOT be used for anything else.
    Str :$method! where /^<!before rpc\.>/,

    # A Structured value that holds the parameter values to be used
    # during the invocation of the method. This member MAY be omitted.
    # (explained in "4.2 Parameter Structures")
    :$params? where {
        # INFO: as explained in RT 109182 lack of presence cannot be tested in signature
        # so "params":null is incorrectly assumed to be to be valid -
        # this is not dangerous because both lack of params or params equals Any()
        # are dispatched to empty signature later
        !$params.defined or $params ~~ Array|Hash
    },

    # An identifier established by the Client that MUST contain
    # a String, Number, or NULL value if included.
    # TODO: replace with Any:U constraint when implemented
    :$id? where {
        !$id.defined or $id ~~ Str|Int|Rat|Num
    }

) {

    # spec version number
    return 2.0;
}

multi method validate_request {

    # none of above spec signatures claimed protocol version number
    JSON::RPC::InvalidRequest.new.throw;
}


method search_method ( Str $name ) {

    # locate public method in application
    my $method = $.application.^find_method( $name );

    JSON::RPC::MethodNotFound.new.throw unless $method;

    return $method;
}

method validate_params ( Routine $method, $params is copy ) {

    # empty params are allowed
    # but Any is not flattenable
    $params //= [ ];

    # find all method candidates that recognize passed params
    my @candidates = $method.candidates_matching( self.application, |$params );

    JSON::RPC::InvalidParams.new.throw unless @candidates;

    # many mathches is not an error
    # first matching candidate is taken
    return @candidates.shift;
}

method call ( Method $candidate, $params is copy ) {

    my $result;

    # empty params are allowed
    # but Any is not flattenable
    $params //= [ ];

    try {
        $result = $candidate.( self.application, |$params );

        CATCH {
            # pass-through error class implemented by user
            when JSON::RPC::Error {
                .rethrow;
            }
            # wrap error reason as internal error
            default {
                JSON::RPC::InternalError.new( data => .Str ).throw;
            }
        }
    };

    return $result;
}
