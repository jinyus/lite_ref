## 0.3.0

-   Make the factory function non-nullable (improves performace and maintainability)

## 0.2.1

-   Internal performance improvements
-   fix minor bug where async singleton would not be replace when overridden

## 0.2.0

-   separate singleton and transient instantiation use: `Ref.singleton`, `Ref.transient`, `Ref.asyncSingleton` and `Ref.asyncTransient`
-   add `assertInstance` getter for synchronous access to a AsyncSingletonRef

## 0.1.0

-   prevent race condition when fetching async singleton
-   add `assertInstance` getter for synchronous access to a LiteAsyncRef
-   add `.freeze()` method which disables overriding

## 0.0.2

-   Update readme

## 0.0.1

-   Initial release
