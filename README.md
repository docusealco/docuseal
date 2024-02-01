<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://www.docuseal.co">
      <img  alt="DocuSeal" src="https://github.com/docusealco/docuseal/assets/5418788/c12cd051-81cd-4402-bc3a-92f2cfdc1b06" width="80" />
      <br>
    </a>
    DocuSeal
  </div>
</h1>
<h3 align="center">
  Open source document filling and signing
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
DocuSeal is an open source platform that provides secure and efficient digital document signing and processing. Create PDF forms to have them filled and signed online on any device with an easy-to-use, mobile-optimized web tool.
</p>
<h2 align="center">
  <a href="https://demo.docuseal.co">✨ Live Demo</a>
  <span>|</span>
  <a href="https://docuseal.co/sign_up">☁️ Try in Cloud</a>
</h2>

[![Demo](https://github.com/docusealco/docuseal/assets/5418788/d8703ea3-361a-423f-8bfe-eff1bd9dbe14)](https://demo.docuseal.co)

## Features
- [x] PDF form fields builder (WYSIWYG)
- [x] 11 field types available (Signature, Date, File, Checkbox etc.)
- [x] Multiple submitters per document
- [x] Automated emails via SMTP
- [x] Files storage on disk or AWS S3, Google Storage, Azure Cloud
- [x] Automatic PDF eSignature
- [x] PDF signature verification
- [x] Users management
- [x] Mobile-optimized
- [x] API and Webhooks for integrations
- [x] Easy to deploy in minutes

## Deploy

|Heroku|Railway|
|:--:|:---:|
| [<img alt="Deploy on Heroku" src="https://www.herokucdn.com/deploy/button.svg" height="40">](https://heroku.com/deploy?template=https://github.com/docusealco/docuseal-heroku) | [<img alt="Deploy on Railway" src="https://railway.app/button.svg" height="40">](https://railway.app/template/IGoDnc?referralCode=ruU7JR)|
|**DigitalOcean**|**Render**|
| [<img alt="Deploy on DigitalOcean" src="https://www.deploytodo.com/do-btn-blue.svg" height="40">](https://cloud.digitalocean.com/apps/new?repo=https://github.com/docusealco/docuseal-digitalocean/tree/master&refcode=421d50f53990) | [<img alt="Deploy to Render" src="https://render.com/images/deploy-to-render-button.svg" height="40">](https://render.com/deploy?repo=https://github.com/docusealco/docuseal-render)
|**Koyeb**|**Elestio**|
| [<img alt="Deploy on Koyeb" src="https://www.koyeb.com/static/images/deploy/button.svg" height="40">](https://app.koyeb.com/deploy?name=docuseal&type=docker&image=docker.io/docuseal/docuseal&env[PORT]=8000&env[DATABASE_URL]=CHANGE_ME&env[SECRET_KEY_BASE]=CHANGE_ME&ports=8000;http;/) | [<img alt="Deploy on Elestio" src="https://pub-da36157c854648669813f3f76c526c2b.r2.dev/deploy-on-elestio-black.png">](https://dash.elest.io/deploy?soft=DocuSeal&id=339) |


#### Docker

```sh
docker run --name docuseal -p 3000:3000 -v.:/data docuseal/docuseal
```

By default DocuSeal docker container uses an SQLite database to store data and configurations. Alternatively, it is possible use PostgreSQL or MySQL databases by specifying the `DATABASE_URL` env variable.

#### Docker Compose

Download docker-compose.yml into your private server:
```sh
curl https://raw.githubusercontent.com/docusealco/docuseal/master/docker-compose.yml > docker-compose.yml
```

Run the app under a custom domain over https using docker compose (make sure your DNS points to the server to automatically issue ssl certs with Caddy):
```sh
sudo HOST=your-domain-name.com docker compose up
```

## For Businesses
### Integrate seamless document signing into your web or mobile apps with DocuSeal!

At DocuSeal we have expertise and technologies to make documents creation, filling, signing and processing seamlessly integrated with your product. We specialize in working with various industries, including **Banking, Healthcare, Transport, Real Estate, eCommerce, KYC, CRM, and other software products** that require bulk document signing. By leveraging DocuSeal, we can assist in reducing the overall cost of developing and processing electronic documents while ensuring security and compliance with local electronic document laws.

[Book a Meeting](https://www.docuseal.co/contact)

## License

Distributed under the AGPLv3 License. See [LICENSE](https://github.com/docusealco/docuseal/blob/master/LICENSE) for more information.
Unless otherwise noted, all files © 2023 DocuSeal LLC.
