<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://www.docuseal.com">
      <img  alt="DocuSeal" src="https://github.com/user-attachments/assets/38b45682-ffa4-4919-abde-d2d422325c44" width="80" />
      <br>
    </a>
    DocuSeal
  </div>
</h1>
<h3 align="center">
  开源文档填写与签署平台
</h3>
<p align="center">
  <a href="https://hub.docker.com/r/docuseal/docuseal">
    <img alt="Docker releases" src="https://img.shields.io/docker/v/docuseal/docuseal">
  </a>
  <a href="https://discord.gg/qygYCDGck9">
    <img src="https://img.shields.io/discord/1125112641170448454?logo=discord"/>
  </a>
  <a href="https://twitter.com/intent/follow?screen_name=docusealco">
    <img src="https://img.shields.io/twitter/follow/docusealco?style=social" alt="Follow @docusealco" />
  </a>
</p>
<p>
DocuSeal 是一个开源平台，提供安全高效的数字文档签署和处理服务。通过易用的、针对移动端优化的网页工具，创建 PDF 表单，让其在任何设备上在线填写和签署。
</p>
<h2 align="center">
  <a href="https://demo.docuseal.tech">✨ 在线演示</a>
  <span>|</span>
  <a href="https://docuseal.com/sign_up">☁️ 云端试用</a>
</h2>

[![Demo](https://github.com/docusealco/docuseal/assets/5418788/d8703ea3-361a-423f-8bfe-eff1bd9dbe14)](https://demo.docuseal.tech)

## 功能特性
- PDF 表单字段构建器（所见即所得）
- 支持 12 种字段类型（签名、日期、文件、复选框等）
- 每份文档支持多个提交人
- 通过 SMTP 自动发送邮件
- 文件存储支持本地磁盘、AWS S3、Google Storage、Azure Cloud
- 自动 PDF 电子签名
- PDF 签名验证
- 用户管理
- 针对移动端优化
- 7 种界面语言，签署支持 14 种语言
- 提供 API 和 Webhooks 用于集成
- 数分钟即可轻松部署

## 专业版功能
- 公司标识和白标定制
- 用户角色管理
- 自动提醒
- 通过短信邀请及身份验证
- 条件字段和公式
- 通过 CSV、XLSX 电子表格批量发送
- SSO / SAML
- 通过 HTML API 创建模板 ([Guide](https://www.docuseal.com/guides/create-pdf-document-fillable-form-with-html-api))
- 通过 PDF 或 DOCX 及字段标签 API 创建模板 ([Guide](https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form))
- 嵌入式签署表单 ([React](https://github.com/docusealco/docuseal-react), [Vue](https://github.com/docusealco/docuseal-vue), [Angular](https://github.com/docusealco/docuseal-angular) or [JavaScript](https://www.docuseal.com/docs/embedded))
- 嵌入式文档表单构建器 ([React](https://github.com/docusealco/docuseal-react), [Vue](https://github.com/docusealco/docuseal-vue), [Angular](https://github.com/docusealco/docuseal-angular) or [JavaScript](https://www.docuseal.com/docs/embedded))
- [了解更多](https://www.docuseal.com/pricing)

## 部署

|Heroku|Railway|
|:--:|:---:|
| [<img alt="Deploy on Heroku" src="https://www.herokucdn.com/deploy/button.svg" height="40">](https://heroku.com/deploy?template=https://github.com/docusealco/docuseal-heroku) | [<img alt="Deploy on Railway" src="https://railway.app/button.svg" height="40">](https://railway.com/deploy/IGoDnc?referralCode=ruU7JR)|
|**DigitalOcean**|**Render**|
| [<img alt="Deploy on DigitalOcean" src="https://www.deploytodo.com/do-btn-blue.svg" height="40">](https://cloud.digitalocean.com/apps/new?repo=https://github.com/docusealco/docuseal-digitalocean/tree/master&refcode=421d50f53990) | [<img alt="Deploy to Render" src="https://render.com/images/deploy-to-render-button.svg" height="40">](https://render.com/deploy?repo=https://github.com/docusealco/docuseal-render)

#### Docker

```sh
docker run --name docuseal -p 3000:3000 -v.:/data docuseal/docuseal
```

默认情况下，DocuSeal Docker 容器使用 SQLite 数据库存储数据和配置。也可以通过设置 `DATABASE_URL` 环境变量来使用 PostgreSQL 或 MySQL 数据库。

#### Docker Compose

将 docker-compose.yml 下载到你的私有服务器：
```sh
curl https://raw.githubusercontent.com/docusealco/docuseal/master/docker-compose.yml > docker-compose.yml
```

使用 docker compose 在自定义域名下通过 https 运行应用（请确保 DNS 已指向服务器，以便通过 Caddy 自动签发 SSL 证书）：
```sh
sudo HOST=your-domain-name.com docker compose up
```

## 企业服务
### 使用 DocuSeal 将无缝文档签署集成到你的 Web 或移动应用中

DocuSeal 拥有专业的技术和经验，能够将文档的创建、填写、签署和处理与你的产品无缝集成。我们专注于服务各行各业，包括**银行、医疗、运输、房地产、电商、KYC、CRM 及其他需要批量文档签署的软件产品**。借助 DocuSeal，我们可以帮助降低开发和处理电子文档的总体成本，同时确保安全性和符合当地电子文档法律法规。

[预约会议](https://www.docuseal.com/contact)

## 许可证

基于 AGPLv3 许可证分发，附带第 7(b) 条附加条款。详见 [LICENSE](https://github.com/docusealco/docuseal/blob/master/LICENSE) 和 [LICENSE_ADDITIONAL_TERMS](https://github.com/docusealco/docuseal/blob/master/LICENSE_ADDITIONAL_TERMS)。
除非另有说明，所有文件 © 2023-2026 DocuSeal LLC。

## 工具

- [签名制作器](https://www.docuseal.com/online-signature)
- [在线签署文档](https://www.docuseal.com/sign-documents-online)
- [在线填写 PDF](https://www.docuseal.com/fill-pdf)

