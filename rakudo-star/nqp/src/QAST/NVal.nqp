class QAST::NVal is QAST::Node {
    has num $!value;
    method value(*@value) { $!value := @value[0] if @value; $!value }
    
    method substitute_inline_placeholders(@fillers) {
        self
    }
}
