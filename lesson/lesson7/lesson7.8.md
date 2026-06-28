# 4. try-catch异常捕获

## 4.1 try-catch基础
try-catch是Solidity中用于捕获外部合约调用异常的机制。它让我们能够优雅地处理外部调用可能出现的各种错误情况。

基本语法：

```sol
try externalContract.someFunction() returns (returnType returnValue) {
    // 成功时执行的代码
} catch Error(string memory reason) {
    // 捕获require/revert的字符串错误
} catch Panic(uint errorCode) {
    // 捕获assert失败和内部错误
} catch (bytes memory lowLevelData) {
    // 捕获其他所有错误（包括自定义错误）
}
```







































































































