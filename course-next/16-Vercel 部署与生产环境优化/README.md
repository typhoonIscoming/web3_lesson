# Vercel 部署与生产环境优化

> **🎓 课程说明**  
> 这份文档是视频教程的完整文字版。它不仅包含了所有的操作步骤，还深入解析了背后的原理。即使你没有观看视频，跟随本文档也能掌握从“本地代码”到“全球化产品”发布的完整技能。

---

## 1. 前言：为什么它是前端部署的终极方案？


大家好！在前面的课程中，我们专注于写代码，构建功能。但代码写得再好，如果还在本地仓库里躺着，那就只是“代码”；只有跑在服务器上被用户访问，它才叫“产品”。

今天这节课，我们的主题只有一个：**上线 (Deployment)**。

如果你以前做过前端部署，可能经历过这样的痛苦流程：买服务器、安装 Node.js、配置 Nginx 反向代理、申请 SSL 证书、设置 SSH 密钥、编写 CI/CD 脚本……这一套下来，半天时间就没了。

![传统部署 vs Vercel 部署对比图](./docs/deploy-compare.svg)

但在 Next.js 的世界里，这一切都成为了历史。因为 Next.js 背后的母公司 **Vercel**，为我们提供了一个堪称“前端云基础设施”的平台。它可以说是部署领域的“苹果”——**极致简单，但又极其强大**。

**对我们开发者来说，最大的好处就是：你只管写代码，剩下的运维工作（服务器、CDN、HTTPS、扩容）全交给它。**

### Vercel 对 Next.js 的“亲儿子”级支持

1.  **Serverless（无服务器架构）**  
    你的 API 路由和 Server Actions 会自动被部署为无服务器函数。没有人访问时不消耗资源，突发流量来了自动扩容，你完全不用担心服务器崩了。

2.  **Edge Network（边缘网络）**  
    Vercel 在全球有数十个边缘节点。你的静态资源（HTML/CSS/JS/图片）会自动分发到离用户最近的节点（CDN），保证全球访问速度极快。

3.  **Image Optimization（图片优化）**  
    我们在代码里用的 `next/image` 组件，在 Vercel 上是零配置自动生效的，自动压缩、自动格式转换。

4.  **永久免费**  
    这对个人开发者最重要，它对个人项目提供非常慷慨的免费额度。

准备好了吗？让我们开始部署！

---

## 2. 零配置部署实战

### 2.1 准备工作
首先，请确保你的代码已经提交到了 GitHub（或者 GitLab/Bitbucket）。
*   主分支通常是 `main`。
*   请确保最后一次提交是干净的。
*   **关键点**：确保你在本地运行 `npm run build` 是能成功的。如果本地构建都报错，推上去肯定也是挂。

### 2.2 导入项目
1.  注册并登录 [Vercel](https://vercel.com)（推荐直接使用 GitHub 账号登录，方便授权）。
2.  进入 Dashboard（控制台），点击 **"Add New Project"**。
3.  在列表中你会看到你的 GitHub 仓库，找到本次课程的项目，点击 **"Import"**。

### 2.3 智能识别（Zero Config）
点击 Import 后，你会看到配置界面。
Vercel 非常智能，它检测到你目录里有 `next.config.mjs` 和 `package.json`，就会自动识别出这是一个 **Next.js** 项目。

*   **Build Command**: 自动填了 `next build`
*   **Output Directory**: 自动填了 `.next`

通常情况下，你**什么都不用改**。这就是传说中的“零配置”。

### 2.4 环境变量配置（🌟 核心步骤）

这是部署过程中唯一需要你需要手动干预的地方。

还记得我们本地开发时用的 `.env.local` 文件吗？那里存放了数据库连接串、GitHub OAuth 的 Secret 等私密信息。因为 `.gitignore` 的存在，这些文件**不会**被上传到 GitHub。

所以，Vercel 的构建服务器现在是拿不到这些变量的。我们需要在这里手动填进去。

**操作步骤**：
1.  展开 **"Environment Variables"** 选项卡。
2.  把你本地 `.env.local` 里的内容，逐个复制过来。
3.  **注意**：`NEXT_PUBLIC_` 开头的变量虽然最终会暴露给浏览器，但在构建阶段也需要用到，所以也**必须**在这里配置。

---

## 3. 深入解析：环境变量的三种使用场景

在等待部署的过程中，我们来深入理解一下 Next.js 环境变量的机制。这是很多初学者最容易晕的地方，弄错了会导致严重的**安全事故**（比如泄露 API Key）。

我们通过三个具体的代码场景来解析：

### 场景 1：服务器端访问（Server Components / API Routes）

在服务器端组件或 API 路由中，我们可以访问**所有**环境变量。这是最安全的地方。

```typescript:app/api/data/route.ts
// API Route 示例
import { NextResponse } from 'next/server';

export async function GET() {
  // ✅ 安全：在服务器端，可以直接访问所有环境变量
  // process.env.DATABASE_URL 仅在服务器内存中存在
  const dbUrl = process.env.DATABASE_URL;
  
  console.log('数据库连接:', dbUrl); 
  
  // 即使你把这个变量 return 出去，也是你显式行为，
  // 默认情况下它们绝不会自动泄露到客户端 bundle 中。
  return NextResponse.json({ success: true });
}
```

### 场景 2：客户端访问（Client Components）

在客户端组件（`'use client'`）中，Next.js 为了安全，会**自动过滤**掉大部分环境变量。**只有**以 `NEXT_PUBLIC_` 开头的变量才会被打包发送到浏览器。

```typescript:components/Header.tsx
// Client Component 示例
'use client';

export default function Header() {
  // ✅ 可访问：带 NEXT_PUBLIC_ 前缀，专用于公开信息
  const siteName = process.env.NEXT_PUBLIC_SITE_NAME;
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  
  // ❌ 无法访问：不带前缀的私密变量，在这里是 undefined
  const secret = process.env.NEXTAUTH_SECRET; 
  
  // 如果你在浏览器控制台打印 secret，会看到 undefined
  // 这就是 Next.js 的安全保护机制
  
  return (
    <header>
      <h1>{siteName}</h1>
      <p>API 地址: {apiUrl}</p>
    </header>
  );
}
```

### 场景 3：混合架构（最佳实践）

如果客户端需要使用某个 API Key（比如天气服务），但这个 Key 又是保密的，不能暴露给浏览器，怎么办？

**答案：做一个“中间人”。**

1.  客户端组件调用我们自己的 **API Route**。
2.  **API Route**（运行在服务器端）去调用第三方服务，它可以使用保密的 Key。
3.  **API Route** 把结果返回给客户端。

```typescript:app/api/weather/route.ts
// API Route（服务器端）
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  // ✅ 这里是服务器端，放心使用私密 Key
  const apiKey = process.env.WEATHER_API_KEY;
  
  // 服务器代为请求第三方
  const res = await fetch(`https://api.weather.com?key=${apiKey}`);
  const data = await res.json();
    
  // 只返回数据，不返回 Key
  return NextResponse.json(data);
}
```

> **🛡️ 环境变量黄金法则**
> *   **私密信息**（API Key、数据库密码、Secret）→ **绝对不加** `NEXT_PUBLIC_` 前缀 → 只在服务器端使用。
> *   **公开配置**（站点名称、公开 API 地址、Google Analytics ID）→ **加** `NEXT_PUBLIC_` 前缀 → 可以在任意地方使用。

---

## 4. 生产环境配置：自定义域名与 HTTPS

部署完成后，Vercel 会送你一个 `xxx.vercel.app` 的域名。这个域名全球可访问，且自动配置了 HTTPS。对于测试项目，这完全够用了。

但如果你想做一个正经的个人品牌或产品，你肯定想要自己的域名（比如 `mars86.com`）。

### 4.1 添加域名
1.  进入 Vercel 项目 Dashboard -> **Settings** -> **Domains**。
2.  在输入框里填入你买好的域名，点击 **Add**。

### 4.2 DNS 配置（给域名办“身份证”）
添加后，Vercel 会提示你配置 DNS。这看起来很技术，其实逻辑很简单：

*   **A 记录**  
    就像域名的“身份证号”。你告诉域名服务商：“当有人访问 `example.com` 时，请把他带到 Vercel 的这个 IP 地址（76.76.21.21）去。”
*   **CNAME 记录**  
    就像“别名”。你告诉服务商：“当有人访问 `www.example.com` 时，请把他转到 `cname.vercel-dns.com`。”

**操作方法**：
登录你的域名购买处（阿里云、腾讯云、GoDaddy），找到 **DNS 解析设置**，照着 Vercel 给出的值填进去就行。

### 4.3 自动 HTTPS

这是最爽的一点。只要 DNS 配置生效（通常几分钟），Vercel 会自动为你申请 **Let's Encrypt** 的 SSL 证书，并部署到服务器上。
以后证书快过期了，它也会**自动续期**。你完全不用管。

---

## 5. 团队协作流：Preview Deployments（预览部署）

Vercel 最杀手级的功能，也是它改变前端开发流程的地方，叫做 **Preview Deployments**。

想象一下：你正在开发一个新功能（比如把按钮改成红色），你不确定好不好看，不敢直接发到线上。在传统流程里，你可能得截图发群里，或者拉个测试环境。

在 Vercel 里，流程是这样的：

1.  **Git 分支**：你在本地切一个新分支 `git checkout -b feature/red-button`。
2.  **提交推送**：改完代码，push 到 GitHub。
3.  **Pull Request**：在 GitHub 上创建一个 Pull Request (PR)。

**奇迹发生了**：
Vercel 的机器人会立刻在这个 PR 下面评论。它会给你一个**预览链接 (Preview URL)**。

*   这是一个**独立的网站**，和线上环境完全隔离。
*   它运行的就是你这个分支的代码。
*   你可以把这个链接发给产品经理、设计师：“来，点开看看效果。”

**Vercel Toolbar（评论功能）**：
你的同事点开链接后，会在页面底部看到一个工具栏。他们可以直接在网页元素上“画圈圈”、写评论：“这个红色太刺眼了，换一个”。这些评论会自动同步回 GitHub。

确认没问题了？点击 **Merge**。代码一合并，Vercel 会再次触发构建，把新代码发布到**生产环境 (Production)**。

**总结流程**：`开发分支` -> `自动预览` -> `团队验证` -> `合并上线`

---

## 6. 生产环境救火：Instant Rollback（快速回滚）

常在河边走，哪有不湿鞋。即使测试再充分，上线后也可能发现严重 Bug。
在传统部署里，回滚是个大工程：`git revert` -> 重新 build -> 重新 upload... 这一套下来 20 分钟过去了，用户早跑光了。

**Vercel 的 Instant Rollback**：

1.  打开 Dashboard -> **Deployments**。
2.  找到 10 分钟前那个“正常”的版本。
3.  点击右侧菜单 -> **"Instant Rollback"**。
4.  **1 秒钟**，进度条走完，线上版本变回去了。

### 为什么这么快？

因为 Vercel 的部署是 **Immutable（不可变）** 的。
每次部署，它都不会覆盖旧文件，而是生成一套全新的文件。
所谓的“上线”，其实就是把域名的指针（路牌）指向了新文件。
所谓的“回滚”，就是把路牌指回旧文件。文件一直都在那，所以不需要重新构建，瞬间完成。

> **⚠️ 重要提示：环境差异**  
> **Instant Rollback 仅适用于生产环境（Production）。**  
> Preview 环境是临时的“实验场”，不需要回滚，有问题直接推新代码就行。只有生产环境这个“正式战场”，才需要这种“后悔药”机制。

---

## 7. 监控与成本优化：做个精打细算的 CTO

网站上线不是结束，只是开始。

### 7.1 Speed Insights（性能监控）
不需要自己接 Google Analytics 或写代码埋点。
1.  在 Vercel Dashboard 点击 **Speed Insights** -> **Enable**。
2.  安装一个小插件：`npm install @vercel/speed-insights`。
3.  在 `app/layout.tsx` 里加一行 `<SpeedInsights />`。

以后你就能看到真实用户的访问速度（LCP）、交互延迟（INP）。这是基于真实用户数据（RUM）的，比 Lighthouse 跑分更有价值。

### 7.2 Logs（实时日志）
如果用户反馈“网站挂了”或者“报错 500”，别瞎猜。
直接去 **Logs** 标签页。这里的日志是实时的，你可以看到服务器端打印的所有 `console.log` 和错误堆栈。这对于调试 API Route 非常有用。

### 7.3 成本优化小贴士 💰
虽然 Vercel 对个人免费，但我们要有良好的工程习惯：

1.  **图片优化**  
    `next/image` 很耗资源。如果你的图片很多，建议使用专门的图片 CDN（如 Cloudinary），然后在 `next.config.mjs` 里把 loader 设为 custom，跳过 Vercel 的优化，这样能省下大量的配额。

2.  **善用缓存**  
    对于不常变的数据，在 API 里设置 `Cache-Control` 头。让 CDN 帮你挡流量，减少后端函数的调用次数。

---

## 8. 结语

恭喜你！到现在为止，你已经掌握了 Next.js 开发的全流程。
从创建项目、编写组件、获取数据，到今天的**自动化部署、预览流、监控回滚**。你现在拥有的，不再是一个简单的 Demo，而是一套可以支撑真实商业产品的**现代化工程体系**。