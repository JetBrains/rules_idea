package examples.test.bin;

import examples.test.foo.*;
import examples.test.bar.*;
import examples.test.baz.*;

public class Main {    
    public static void main(String[] args) {
        Foo foo = new Foo();
        System.out.println(foo.name());
        Bar bar = new Bar();
        System.out.println(bar.name());
        Baz baz = new Baz();
        System.out.println(baz.name());
    }

}
