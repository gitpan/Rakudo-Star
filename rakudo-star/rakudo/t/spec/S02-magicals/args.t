use v6;
use Test;

plan 4;

isa_ok @*ARGS, Array, '@*ARGS is an Array';
is_deeply @*ARGS, [], 'by default @*ARGS is empty array';

lives_ok { @*ARGS = 1, 2 }, '@*ARGS is writable';

BEGIN { @*INC.push: 't/spec/packages' }

use Test::Util;

is_run 'print @*ARGS.join(q[, ])', :args[1, 2, "foo"],
    {
        out => '1, 2, foo',
        err => '',
        status => 0,
    }, 'providing command line arguments sets @*ARGS';

done;
