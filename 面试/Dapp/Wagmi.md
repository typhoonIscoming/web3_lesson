### Wagmi 面试题

#### 基础概念题
1. **什么是 wagmi? 它的主要作用是什么？**
答：wagmi 是一个用于 React 的以太坊 hooks 库，主要用于简化 Web3 应用开发。它提供了一系列 hooks 来处理钱包连接、合约交互、交易发送等常见 Web3 功能。

2. **wagmi 相比其他 Web3 库（如 web3.js、ethers.js）有什么优势？**
答：
- 基于 React Hooks，更符合 React 生态
- 内置状态管理和缓存机制
- 自动处理重连和错误
- TypeScript 支持更好
- 更现代化的 API 设计

#### 进阶实践题
3. **如何在 wagmi 中实现多链支持？请详细说明配置过程。**
```typescript
import { configureChains, createConfig } from 'wagmi'
import { mainnet, optimism, polygon } from 'wagmi/chains'
import { publicProvider } from 'wagmi/providers/public'

const { chains, publicClient } = configureChains(
  [mainnet, optimism, polygon],
  [publicProvider()]
)

const config = createConfig({
  autoConnect: true,
  publicClient,
  chains
})
```

4. **wagmi 中的 prepare hooks 和 write hooks 有什么区别？为什么要这样设计？**
答：
- prepare hooks (如 usePrepareContractWrite) 用于预先验证交易
- write hooks (如 useContractWrite) 用于执行实际交易
- 这种设计可以提前发现错误，优化用户体验，节省 gas

#### 源码相关题
5. **wagmi 是如何管理全局状态的？请解释其状态管理机制。**
答：wagmi 使用 `@tanstack/query` (原 react-query) 作为状态管理工具，源码中通过 `createStore` 创建存储，主要管理：
- 钱包连接状态
- 网络状态
- 合约状态
- 交易记录等

6. **解释 wagmi 中的 Provider 实现原理**
```typescript
// 简化版源码分析
export function WagmiConfig({ config, children }: WagmiConfigProps) {
  return (
    <WagmiContext.Provider value={config}>
      <QueryClientProvider client={config.queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiContext.Provider>
  )
}
```

7. **wagmi 是如何处理钱包连接的？请解释其连接流程。**
答：主要通过 `useConnect` hook 实现：
1. 检查本地存储的连接记录
2. 调用相应钱包的 connect 方法
3. 更新全局状态
4. 监听钱包事件
5. 处理断开重连

#### 实战题
8. **如何使用 wagmi 实现一个 ERC20 代币转账功能？请写出关键代码。**
```typescript
import { useContractWrite, usePrepareContractWrite } from 'wagmi'

const { config } = usePrepareContractWrite({
  address: '0x...',
  abi: erc20ABI,
  functionName: 'transfer',
  args: [recipient, amount]
})

const { write, isLoading, isSuccess } = useContractWrite(config)
```

9. **wagmi 中的错误处理机制是怎样的？如何优雅地处理各种错误情况？**
答：wagmi 提供了多层错误处理：
- 预执行错误（prepare hooks）
- 执行错误（write hooks）
- 网络错误
- 用户拒绝错误
建议使用 try-catch 配合 wagmi 提供的错误状态进行处理。

10. **wagmi 的缓存机制是如何工作的？请解释其缓存策略。**
答：wagmi 利用 `@tanstack/query` 的缓存机制：
- 查询缓存：缓存链上数据查询结果
- 状态缓存：缓存连接状态
- 配置缓存：缓存用户配置
- 支持自定义缓存时间和失效策略



tip： 面试时对方大概率会根据你的回答深入追问相关细节。