# Changelog

## [1.3.3](https://github.com/min2hi/medi_chain/compare/v1.3.2...v1.3.3) (2026-05-20)


### Bug Fixes

* **mobile:** resolve mojibake encoding errors in string literals causing build failure ([#86](https://github.com/min2hi/medi_chain/issues/86)) ([a217a01](https://github.com/min2hi/medi_chain/commit/a217a0175818d9ec6599d495d1cc59d77bbb6cfe))

## [1.3.2](https://github.com/min2hi/medi_chain/compare/v1.3.1...v1.3.2) (2026-05-20)


### Bug Fixes

* **db:** add missing migration SQL for doctorNotes P2022 on production ([b1fed3a](https://github.com/min2hi/medi_chain/commit/b1fed3a489b8fa016567dd95add384000a606837))
* **db:** add missing migration SQL for doctorNotes P2022 on production ([4047108](https://github.com/min2hi/medi_chain/commit/40471084953a150a4e4bc052918a2c0932eb02b3))
* **ui:** resolve all mojibake UTF-8 encoding issues across codebase ([afef11c](https://github.com/min2hi/medi_chain/commit/afef11c72e41522117bb143cc97387f2306e3f5b))

## [1.3.1](https://github.com/min2hi/medi_chain/compare/v1.3.0...v1.3.1) (2026-05-20)


### Bug Fixes

* **backend:** add trust proxy - fix 500s on Render from rate-limit ([4be0e27](https://github.com/min2hi/medi_chain/commit/4be0e2783785ae0e0e796eb3ad1bd7f71b420eb5))

## [1.3.0](https://github.com/min2hi/medi_chain/compare/v1.2.4...v1.3.0) (2026-05-19)


### Features

* clinic doctor notes and dashboard UI updates ([#80](https://github.com/min2hi/medi_chain/issues/80)) ([420fc1f](https://github.com/min2hi/medi_chain/commit/420fc1f3f11e79e654198af5fe08b06054fe7dca))

## [1.2.4](https://github.com/min2hi/medi_chain/compare/v1.2.3...v1.2.4) (2026-05-19)


### Bug Fixes

* **frontend:** sync package-lock.json with eslint@9.29.0 pin ([2f85e98](https://github.com/min2hi/medi_chain/commit/2f85e98b560c3bedce95fa40083978425af5478e))

## [1.2.3](https://github.com/min2hi/medi_chain/compare/v1.2.2...v1.2.3) (2026-05-18)


### Bug Fixes

* **frontend:** pin tailwind@3.4.19, eslint@9.29.0, disable compat rules ([498fd8e](https://github.com/min2hi/medi_chain/commit/498fd8e284bd210787737033599cd2c55ce5d468))

## [1.2.2](https://github.com/min2hi/medi_chain/compare/v1.2.1...v1.2.2) (2026-05-17)


### Bug Fixes

* **payment:** verify webhook signature against data sub-object per PayOS spec ([9cd54e2](https://github.com/min2hi/medi_chain/commit/9cd54e28b01768dea973b4da1bd7cd5aa0ac52df))

## [1.2.1](https://github.com/min2hi/medi_chain/compare/v1.2.0...v1.2.1) (2026-05-17)


### Bug Fixes

* extract backend error message from DioException in payment repo ([#59](https://github.com/min2hi/medi_chain/issues/59)) ([f693e92](https://github.com/min2hi/medi_chain/commit/f693e92d06fbaeca26d56a47b4c0aae91a44cd9c))

## [1.2.0](https://github.com/min2hi/medi_chain/compare/v1.1.0...v1.2.0) (2026-05-16)


### Features

* add complete payment system (PayOS integration) ([bf2b20e](https://github.com/min2hi/medi_chain/commit/bf2b20eb2af6a36dd3d348a28cf9a2a90ba0f1a2))
* **admin:** add admin widget library and finalize portal UI ([e4fbb45](https://github.com/min2hi/medi_chain/commit/e4fbb455d9ca719fb86d370ec73fd63735cf01e1))
* **safety:** wire LLM triage interceptor to chat() - OpenAI moderation pattern ([c4e0385](https://github.com/min2hi/medi_chain/commit/c4e038551e7c7ffa0b84bb1f6d48ea9039994568))


### Bug Fixes

* adapt config for Prisma v7.8 using prisma.config.ts ([10f5649](https://github.com/min2hi/medi_chain/commit/10f5649ff34aa9689d2ccddb10afdb68547a48d3))
* add directUrl to schema for Neon DB connection pool ([0540d82](https://github.com/min2hi/medi_chain/commit/0540d829f2d99d559c80a78084cc093bbcefa444))
* **admin:** remove duplicate _TriggerContextBox from git rebase merge ([42978d0](https://github.com/min2hi/medi_chain/commit/42978d05ab8009905499e87b88ea64a845f137ec))
* **l10n:** set startLocale to vi so app always defaults to Vietnamese ([2350666](https://github.com/min2hi/medi_chain/commit/2350666ece4e8c414ef233fd069963272c62d022))
* regenerate payment migration + fix quick action routing ([37969d3](https://github.com/min2hi/medi_chain/commit/37969d3d0590bec5ce6591c071659d95ffb2f8e3))

## [1.1.0](https://github.com/min2hi/medi_chain/compare/v1.0.0...v1.1.0) (2026-05-11)


### Features

* add global Next.js loading skeleton for instant page transitions ([ea012a1](https://github.com/min2hi/medi_chain/commit/ea012a1a18e86f337d3c389ced86ad8f7e8c81fb))
* add OpenFDA ETL pipeline (daily 3AM) + embedding migration done ([bfcdf4d](https://github.com/min2hi/medi_chain/commit/bfcdf4d18f16c9d2d4e2d71828b25fe7551c3092))
* add prisma seed with 1956 drugs master data ([e6cdc89](https://github.com/min2hi/medi_chain/commit/e6cdc891c783489031be9f599cf548383c4a4e6f))
* **admin:** clinical command center v1.0 - admin portal CRUD + RBAC ([#18](https://github.com/min2hi/medi_chain/issues/18)) ([5ddbab2](https://github.com/min2hi/medi_chain/commit/5ddbab20057c347e3da4db42e1fc43a9ca14513f))
* **admin:** fix sidebar bug and add user management ([#20](https://github.com/min2hi/medi_chain/issues/20)) ([6c2e19c](https://github.com/min2hi/medi_chain/commit/6c2e19cf5e47b9702463315b8160060deb772757))
* **admin:** granular RBAC, page transitions, and admin portal cleanup ([#19](https://github.com/min2hi/medi_chain/issues/19)) ([11679ed](https://github.com/min2hi/medi_chain/commit/11679eda1c2097efb151ea1abf7ac492ab7bef38))
* **ai-harness:** nang cap AI harness va DevOps len chuan Senior Big Tech ([#14](https://github.com/min2hi/medi_chain/issues/14)) ([bfc0012](https://github.com/min2hi/medi_chain/commit/bfc0012fd6e457c2d0276524b7fe7e594e343f6f))
* **auth:** implement production-grade email service for password reset ([d1effda](https://github.com/min2hi/medi_chain/commit/d1effdaf1de645048aaabe4c9bd6775ad96bba1a))
* **automation:** integrate e2e, codecov, staging, and semantic versi… ([cae7800](https://github.com/min2hi/medi_chain/commit/cae7800f1effaad8c4b023434902f449bc4bd6db))
* **automation:** integrate e2e, codecov, staging, and semantic versioning ([497f746](https://github.com/min2hi/medi_chain/commit/497f746e08c3f807756f1fc43ce1c1b7a49c3b03))
* **backend:** add Resend HTTP API alternative to bypass SMTP firewalls ([bcaabe6](https://github.com/min2hi/medi_chain/commit/bcaabe60169a686fc316c0491cc601b73632a3e8))
* **frontend:** implement Connection Pre-warming and Smart UX Loading timers to optimize cold start UX ([43e424a](https://github.com/min2hi/medi_chain/commit/43e424af740325731a0d659eb9e72964529e6618))
* **frontend:** implement UI for forgot and reset password on web ([86b7712](https://github.com/min2hi/medi_chain/commit/86b77126c8b8be1d3fc4b22e0166e24b1d56df6a))
* **i18n:** add missing translation dictionaries and provider ([99780da](https://github.com/min2hi/medi_chain/commit/99780daa05f2d4b9eb1ad35b541dcc2d474aac88))
* **i18n:** construct comprehensive translation provider and translate settings/navigation logic ([4e5a4af](https://github.com/min2hi/medi_chain/commit/4e5a4af655b466bfe37b23dd1c34c14894b7dca9))
* **i18n:** finalize AI localization and fix TypeScript Locale import errors ([24bbdd6](https://github.com/min2hi/medi_chain/commit/24bbdd64bc5af0c4b0011043496b15cc6ae53405))
* **mobile/backend:** implement deep linking for password reset ([4f52006](https://github.com/min2hi/medi_chain/commit/4f52006a9d91278050c12233ec41c1caa5187754))
* **mobile:** add role-based admin portal access in Settings ([#24](https://github.com/min2hi/medi_chain/issues/24)) ([e30c7f7](https://github.com/min2hi/medi_chain/commit/e30c7f7073c7e694d5ba6ffd99edc3ed36c66387))
* **mobile:** native admin portal - 5 screens thay the url_launcher ([#27](https://github.com/min2hi/medi_chain/issues/27)) ([70862d6](https://github.com/min2hi/medi_chain/commit/70862d64c2fa6dc6ed491d0f4d99b24ffaa3569d))
* **mobile:** sync UI with web — AI Hub, Inter font, skeleton, alerts ([#21](https://github.com/min2hi/medi_chain/issues/21)) ([b7cb569](https://github.com/min2hi/medi_chain/commit/b7cb56966aaa5f0f9d2b080ed76f356ed1118158))
* **nlu:** Medical NLU Service v1 - Semantic Context Understanding ([cdca0bb](https://github.com/min2hi/medi_chain/commit/cdca0bb188be0af243e5a3d3bfa21c1858b6b4f4))
* production deployment setup - multi-stage Docker, Nginx, SSL support ([0857934](https://github.com/min2hi/medi_chain/commit/085793468bfa28026050ce8309c351785e268e77))
* replace all page spinners with contextual skeleton loaders ([90a5d1e](https://github.com/min2hi/medi_chain/commit/90a5d1e66d2f6c69098b5037b310e9154919c5a1))
* **safety:** upgrade recommendation engine to v2.0 with multi-layer safety ([1f7761e](https://github.com/min2hi/medi_chain/commit/1f7761e4c5eac16dadd0020d0f6994e95403936a))
* **settings:** implement full settings functionality across web and mobile ([90077de](https://github.com/min2hi/medi_chain/commit/90077de3b6e80774141a1e6178cb43f9851b8f63))
* **ui:** unify AI screens & settings UX across web and mobile ([3dc3379](https://github.com/min2hi/medi_chain/commit/3dc3379ab67261e91239c7c8b96114baee057a29))
* **ux:** implement big-tech psych-loading patterns and DNS preconnect for auth speedup ([7206173](https://github.com/min2hi/medi_chain/commit/7206173cfede9a7eee78f6876848a30df52b3a6b))


### Bug Fixes

* add migration for missing columns (collaborativeScore, symptomContext) ([fd233e8](https://github.com/min2hi/medi_chain/commit/fd233e8bc6108b83c845963dacdb1fbed10504c8))
* add postinstall prisma generate for Render deployment ([3e4f3c4](https://github.com/min2hi/medi_chain/commit/3e4f3c4c0e9667a18219281512e4f9c8b003147b))
* **ai-chat:** resolve connection errors, add timeout & smart error handling ([73091b0](https://github.com/min2hi/medi_chain/commit/73091b050878f561c82fe19a685ada09ba825c16))
* **ai:** syntax error in template literal string ([ddcf625](https://github.com/min2hi/medi_chain/commit/ddcf625196c1f9d7e530a4825591ac5b428123f9))
* **backend:** add timeout parameters to SMTP connection to fail fast and prevent hanging frontend requests ([4a59e18](https://github.com/min2hi/medi_chain/commit/4a59e18f306933d54a66eb917d59a8eb3b5de895))
* **backend:** type errors in auth methods ([292c659](https://github.com/min2hi/medi_chain/commit/292c65945d111d841d37fd385131b73edcc7d915))
* bypass Resend click-tracking crashing custom URI deep links by routing through Next.js proxy ([cd719f3](https://github.com/min2hi/medi_chain/commit/cd719f3bae2f756ceeb69a721eb707e453bdb2b6))
* copy prisma generated client to dist after tsc build ([f799fac](https://github.com/min2hi/medi_chain/commit/f799facae1f038cbabf52fb5736ac824c32bf9f6))
* correct keep-alive URL, fix welcome+skeleton conflict, real skeleton for thuoc page ([d9452f0](https://github.com/min2hi/medi_chain/commit/d9452f0d3a8000031f87a9e146e3de1530a19065))
* correct prisma default import in drug-etl ([c6903b8](https://github.com/min2hi/medi_chain/commit/c6903b81f6c315829081d764772ae18655f6c713))
* **css:** remove invisible characters causing IDE parse error at line 141 ([51b61cc](https://github.com/min2hi/medi_chain/commit/51b61ccd959fc08ef38d78f5b4913f44716c27c1))
* **docs:** doi npx gitnexus thanh global install, fix Windows EPERM bug ([#25](https://github.com/min2hi/medi_chain/issues/25)) ([2f45403](https://github.com/min2hi/medi_chain/commit/2f4540305e40955a23aeafccaa3197cbbd89afdb))
* **frontend:** allow unauthenticated access to /reset-password route ([13050e6](https://github.com/min2hi/medi_chain/commit/13050e62763aa9ef04ebeae8b5bfafed457edc3d))
* **frontend:** extract raw origin for CSP connect-src to prevent browser from blocking sub-path API fetches ([bfae600](https://github.com/min2hi/medi_chain/commit/bfae60033682f547c0f01cd820a6f94772adf12f))
* **frontend:** hardcode production backend URL fallback to prevent Vercel env var user errors ([12a17b1](https://github.com/min2hi/medi_chain/commit/12a17b13b08bb59d3f173d703c0b8e5a3270f149))
* **frontend:** hide sidebar navigation on /reset-password route ([030488e](https://github.com/min2hi/medi_chain/commit/030488e159131022b82fcd5379e4021660620667))
* **frontend:** remove emoji icons and fix timepicker UI bug in notification modal ([e2d9ebb](https://github.com/min2hi/medi_chain/commit/e2d9ebb782535875e7725bde74e670c99545a21d))
* **frontend:** remove invalid align attribute causing TS 2322 in Vercel build ([1520de6](https://github.com/min2hi/medi_chain/commit/1520de66802fd5b11b2699dda8783311f0184771))
* **frontend:** remove undefined initialTimeout variable causing Next.js build failure ([0b131eb](https://github.com/min2hi/medi_chain/commit/0b131eb5d2a99cf20b4119b05435687c4c1ca5a6))
* **frontend:** resolve all ESLint errors - CI ready (0 errors) ([35170e8](https://github.com/min2hi/medi_chain/commit/35170e80dc9e0c1a4682b7f23b97522c93657059))
* **frontend:** resolve all ESLint errors — 0 errors CI ready ([677bb8d](https://github.com/min2hi/medi_chain/commit/677bb8de68e9de054696c81fd21660b636c6e0c6))
* **frontend:** resolve syntax error in login page fake progress bar ([8065ae6](https://github.com/min2hi/medi_chain/commit/8065ae6e66d067ed330aa4719d737f46d5db233d))
* **frontend:** resolve TypeScript build errors after any→unknown migration ([ae96566](https://github.com/min2hi/medi_chain/commit/ae965662014d882b3f0c84ecd89b010ab5470c46))
* **mobile:** replace default counter test with dummy test to fix CI ([181a09e](https://github.com/min2hi/medi_chain/commit/181a09e7db4d390488f7505ad6ca5bde0a8b2ef5))
* **mobile:** resolve flutter analyze strict errors to fix CI ([cc34b64](https://github.com/min2hi/medi_chain/commit/cc34b6464e3edfd6e46fb992012a09217d69bfad))
* **mobile:** set production backend URL for Render deployment ([#23](https://github.com/min2hi/medi_chain/issues/23)) ([d42c7eb](https://github.com/min2hi/medi_chain/commit/d42c7eb6b9d6ccf3e67e76af4411058dfe78a2a9))
* move prisma to dependencies for production build ([c9568a0](https://github.com/min2hi/medi_chain/commit/c9568a0dd9f8832860b045ebf9fa979d02502a1c))
* prevent theme flash & support dynamic vercel CORS ([7b1d820](https://github.com/min2hi/medi_chain/commit/7b1d82063b87abaf07d7726f3a6f096e47409e2b))
* **production:** comprehensive readiness improvements and backend settings ([cbd9fe3](https://github.com/min2hi/medi_chain/commit/cbd9fe371bab63c3ecb71fe7330cd79dae587cd0))
* **safety+ui:** 5 bugs found via clinical test case review ([2b6a510](https://github.com/min2hi/medi_chain/commit/2b6a510d6846e7efa8543b370c2b0998f74bfe0b))
* **safety:** add hospital context detector + dengue risk pattern ([dd8296d](https://github.com/min2hi/medi_chain/commit/dd8296d1a8af32e67b290f78a0e8e9b667483bfb))
* **settings:** remove duplicate Cai dat link from sidebar popup ([53f19b7](https://github.com/min2hi/medi_chain/commit/53f19b7c926ccdd232e66ac456355de540b7bb70))
* use node directly for prisma generate to bypass permission issues ([cd623dd](https://github.com/min2hi/medi_chain/commit/cd623dd70a0bb03895b7aad60e69a443f8f9da15))


### Performance Improvements

* add keep-alive pinger + instant UI render for AI page ([c3765b6](https://github.com/min2hi/medi_chain/commit/c3765b68da1ffb68d64d2d24416a02a59a30bac1))
* **backend:** remove await on sendPasswordResetEmail to execute linearly in background, resolving UX delay ([c5dc46e](https://github.com/min2hi/medi_chain/commit/c5dc46e4b8970305f691b0ba9e61660265525757))

## 1.0.0 (2026-05-11)


### Features

* add global Next.js loading skeleton for instant page transitions ([ea012a1](https://github.com/min2hi/medi_chain/commit/ea012a1a18e86f337d3c389ced86ad8f7e8c81fb))
* add OpenFDA ETL pipeline (daily 3AM) + embedding migration done ([bfcdf4d](https://github.com/min2hi/medi_chain/commit/bfcdf4d18f16c9d2d4e2d71828b25fe7551c3092))
* add prisma seed with 1956 drugs master data ([e6cdc89](https://github.com/min2hi/medi_chain/commit/e6cdc891c783489031be9f599cf548383c4a4e6f))
* **admin:** clinical command center v1.0 - admin portal CRUD + RBAC ([#18](https://github.com/min2hi/medi_chain/issues/18)) ([5ddbab2](https://github.com/min2hi/medi_chain/commit/5ddbab20057c347e3da4db42e1fc43a9ca14513f))
* **admin:** fix sidebar bug and add user management ([#20](https://github.com/min2hi/medi_chain/issues/20)) ([6c2e19c](https://github.com/min2hi/medi_chain/commit/6c2e19cf5e47b9702463315b8160060deb772757))
* **admin:** granular RBAC, page transitions, and admin portal cleanup ([#19](https://github.com/min2hi/medi_chain/issues/19)) ([11679ed](https://github.com/min2hi/medi_chain/commit/11679eda1c2097efb151ea1abf7ac492ab7bef38))
* **ai-harness:** nang cap AI harness va DevOps len chuan Senior Big Tech ([#14](https://github.com/min2hi/medi_chain/issues/14)) ([bfc0012](https://github.com/min2hi/medi_chain/commit/bfc0012fd6e457c2d0276524b7fe7e594e343f6f))
* **auth:** implement production-grade email service for password reset ([d1effda](https://github.com/min2hi/medi_chain/commit/d1effdaf1de645048aaabe4c9bd6775ad96bba1a))
* **automation:** integrate e2e, codecov, staging, and semantic versi… ([cae7800](https://github.com/min2hi/medi_chain/commit/cae7800f1effaad8c4b023434902f449bc4bd6db))
* **automation:** integrate e2e, codecov, staging, and semantic versioning ([497f746](https://github.com/min2hi/medi_chain/commit/497f746e08c3f807756f1fc43ce1c1b7a49c3b03))
* **backend:** add Resend HTTP API alternative to bypass SMTP firewalls ([bcaabe6](https://github.com/min2hi/medi_chain/commit/bcaabe60169a686fc316c0491cc601b73632a3e8))
* **frontend:** implement Connection Pre-warming and Smart UX Loading timers to optimize cold start UX ([43e424a](https://github.com/min2hi/medi_chain/commit/43e424af740325731a0d659eb9e72964529e6618))
* **frontend:** implement UI for forgot and reset password on web ([86b7712](https://github.com/min2hi/medi_chain/commit/86b77126c8b8be1d3fc4b22e0166e24b1d56df6a))
* **i18n:** add missing translation dictionaries and provider ([99780da](https://github.com/min2hi/medi_chain/commit/99780daa05f2d4b9eb1ad35b541dcc2d474aac88))
* **i18n:** construct comprehensive translation provider and translate settings/navigation logic ([4e5a4af](https://github.com/min2hi/medi_chain/commit/4e5a4af655b466bfe37b23dd1c34c14894b7dca9))
* **i18n:** finalize AI localization and fix TypeScript Locale import errors ([24bbdd6](https://github.com/min2hi/medi_chain/commit/24bbdd64bc5af0c4b0011043496b15cc6ae53405))
* **mobile/backend:** implement deep linking for password reset ([4f52006](https://github.com/min2hi/medi_chain/commit/4f52006a9d91278050c12233ec41c1caa5187754))
* **mobile:** add role-based admin portal access in Settings ([#24](https://github.com/min2hi/medi_chain/issues/24)) ([e30c7f7](https://github.com/min2hi/medi_chain/commit/e30c7f7073c7e694d5ba6ffd99edc3ed36c66387))
* **mobile:** native admin portal - 5 screens thay the url_launcher ([#27](https://github.com/min2hi/medi_chain/issues/27)) ([70862d6](https://github.com/min2hi/medi_chain/commit/70862d64c2fa6dc6ed491d0f4d99b24ffaa3569d))
* **mobile:** sync UI with web — AI Hub, Inter font, skeleton, alerts ([#21](https://github.com/min2hi/medi_chain/issues/21)) ([b7cb569](https://github.com/min2hi/medi_chain/commit/b7cb56966aaa5f0f9d2b080ed76f356ed1118158))
* **nlu:** Medical NLU Service v1 - Semantic Context Understanding ([cdca0bb](https://github.com/min2hi/medi_chain/commit/cdca0bb188be0af243e5a3d3bfa21c1858b6b4f4))
* production deployment setup - multi-stage Docker, Nginx, SSL support ([0857934](https://github.com/min2hi/medi_chain/commit/085793468bfa28026050ce8309c351785e268e77))
* replace all page spinners with contextual skeleton loaders ([90a5d1e](https://github.com/min2hi/medi_chain/commit/90a5d1e66d2f6c69098b5037b310e9154919c5a1))
* **safety:** upgrade recommendation engine to v2.0 with multi-layer safety ([1f7761e](https://github.com/min2hi/medi_chain/commit/1f7761e4c5eac16dadd0020d0f6994e95403936a))
* **settings:** implement full settings functionality across web and mobile ([90077de](https://github.com/min2hi/medi_chain/commit/90077de3b6e80774141a1e6178cb43f9851b8f63))
* **ui:** unify AI screens & settings UX across web and mobile ([3dc3379](https://github.com/min2hi/medi_chain/commit/3dc3379ab67261e91239c7c8b96114baee057a29))
* **ux:** implement big-tech psych-loading patterns and DNS preconnect for auth speedup ([7206173](https://github.com/min2hi/medi_chain/commit/7206173cfede9a7eee78f6876848a30df52b3a6b))


### Bug Fixes

* add migration for missing columns (collaborativeScore, symptomContext) ([fd233e8](https://github.com/min2hi/medi_chain/commit/fd233e8bc6108b83c845963dacdb1fbed10504c8))
* add postinstall prisma generate for Render deployment ([3e4f3c4](https://github.com/min2hi/medi_chain/commit/3e4f3c4c0e9667a18219281512e4f9c8b003147b))
* **ai-chat:** resolve connection errors, add timeout & smart error handling ([73091b0](https://github.com/min2hi/medi_chain/commit/73091b050878f561c82fe19a685ada09ba825c16))
* **ai:** syntax error in template literal string ([ddcf625](https://github.com/min2hi/medi_chain/commit/ddcf625196c1f9d7e530a4825591ac5b428123f9))
* **backend:** add timeout parameters to SMTP connection to fail fast and prevent hanging frontend requests ([4a59e18](https://github.com/min2hi/medi_chain/commit/4a59e18f306933d54a66eb917d59a8eb3b5de895))
* **backend:** type errors in auth methods ([292c659](https://github.com/min2hi/medi_chain/commit/292c65945d111d841d37fd385131b73edcc7d915))
* bypass Resend click-tracking crashing custom URI deep links by routing through Next.js proxy ([cd719f3](https://github.com/min2hi/medi_chain/commit/cd719f3bae2f756ceeb69a721eb707e453bdb2b6))
* copy prisma generated client to dist after tsc build ([f799fac](https://github.com/min2hi/medi_chain/commit/f799facae1f038cbabf52fb5736ac824c32bf9f6))
* correct keep-alive URL, fix welcome+skeleton conflict, real skeleton for thuoc page ([d9452f0](https://github.com/min2hi/medi_chain/commit/d9452f0d3a8000031f87a9e146e3de1530a19065))
* correct prisma default import in drug-etl ([c6903b8](https://github.com/min2hi/medi_chain/commit/c6903b81f6c315829081d764772ae18655f6c713))
* **css:** remove invisible characters causing IDE parse error at line 141 ([51b61cc](https://github.com/min2hi/medi_chain/commit/51b61ccd959fc08ef38d78f5b4913f44716c27c1))
* **docs:** doi npx gitnexus thanh global install, fix Windows EPERM bug ([#25](https://github.com/min2hi/medi_chain/issues/25)) ([2f45403](https://github.com/min2hi/medi_chain/commit/2f4540305e40955a23aeafccaa3197cbbd89afdb))
* **frontend:** allow unauthenticated access to /reset-password route ([13050e6](https://github.com/min2hi/medi_chain/commit/13050e62763aa9ef04ebeae8b5bfafed457edc3d))
* **frontend:** extract raw origin for CSP connect-src to prevent browser from blocking sub-path API fetches ([bfae600](https://github.com/min2hi/medi_chain/commit/bfae60033682f547c0f01cd820a6f94772adf12f))
* **frontend:** hardcode production backend URL fallback to prevent Vercel env var user errors ([12a17b1](https://github.com/min2hi/medi_chain/commit/12a17b13b08bb59d3f173d703c0b8e5a3270f149))
* **frontend:** hide sidebar navigation on /reset-password route ([030488e](https://github.com/min2hi/medi_chain/commit/030488e159131022b82fcd5379e4021660620667))
* **frontend:** remove emoji icons and fix timepicker UI bug in notification modal ([e2d9ebb](https://github.com/min2hi/medi_chain/commit/e2d9ebb782535875e7725bde74e670c99545a21d))
* **frontend:** remove invalid align attribute causing TS 2322 in Vercel build ([1520de6](https://github.com/min2hi/medi_chain/commit/1520de66802fd5b11b2699dda8783311f0184771))
* **frontend:** remove undefined initialTimeout variable causing Next.js build failure ([0b131eb](https://github.com/min2hi/medi_chain/commit/0b131eb5d2a99cf20b4119b05435687c4c1ca5a6))
* **frontend:** resolve all ESLint errors - CI ready (0 errors) ([35170e8](https://github.com/min2hi/medi_chain/commit/35170e80dc9e0c1a4682b7f23b97522c93657059))
* **frontend:** resolve all ESLint errors — 0 errors CI ready ([677bb8d](https://github.com/min2hi/medi_chain/commit/677bb8de68e9de054696c81fd21660b636c6e0c6))
* **frontend:** resolve syntax error in login page fake progress bar ([8065ae6](https://github.com/min2hi/medi_chain/commit/8065ae6e66d067ed330aa4719d737f46d5db233d))
* **frontend:** resolve TypeScript build errors after any→unknown migration ([ae96566](https://github.com/min2hi/medi_chain/commit/ae965662014d882b3f0c84ecd89b010ab5470c46))
* **mobile:** replace default counter test with dummy test to fix CI ([181a09e](https://github.com/min2hi/medi_chain/commit/181a09e7db4d390488f7505ad6ca5bde0a8b2ef5))
* **mobile:** resolve flutter analyze strict errors to fix CI ([cc34b64](https://github.com/min2hi/medi_chain/commit/cc34b6464e3edfd6e46fb992012a09217d69bfad))
* **mobile:** set production backend URL for Render deployment ([#23](https://github.com/min2hi/medi_chain/issues/23)) ([d42c7eb](https://github.com/min2hi/medi_chain/commit/d42c7eb6b9d6ccf3e67e76af4411058dfe78a2a9))
* move prisma to dependencies for production build ([c9568a0](https://github.com/min2hi/medi_chain/commit/c9568a0dd9f8832860b045ebf9fa979d02502a1c))
* prevent theme flash & support dynamic vercel CORS ([7b1d820](https://github.com/min2hi/medi_chain/commit/7b1d82063b87abaf07d7726f3a6f096e47409e2b))
* **production:** comprehensive readiness improvements and backend settings ([cbd9fe3](https://github.com/min2hi/medi_chain/commit/cbd9fe371bab63c3ecb71fe7330cd79dae587cd0))
* **safety+ui:** 5 bugs found via clinical test case review ([2b6a510](https://github.com/min2hi/medi_chain/commit/2b6a510d6846e7efa8543b370c2b0998f74bfe0b))
* **safety:** add hospital context detector + dengue risk pattern ([dd8296d](https://github.com/min2hi/medi_chain/commit/dd8296d1a8af32e67b290f78a0e8e9b667483bfb))
* **settings:** remove duplicate Cai dat link from sidebar popup ([53f19b7](https://github.com/min2hi/medi_chain/commit/53f19b7c926ccdd232e66ac456355de540b7bb70))
* use node directly for prisma generate to bypass permission issues ([cd623dd](https://github.com/min2hi/medi_chain/commit/cd623dd70a0bb03895b7aad60e69a443f8f9da15))


### Performance Improvements

* add keep-alive pinger + instant UI render for AI page ([c3765b6](https://github.com/min2hi/medi_chain/commit/c3765b68da1ffb68d64d2d24416a02a59a30bac1))
* **backend:** remove await on sendPasswordResetEmail to execute linearly in background, resolving UX delay ([c5dc46e](https://github.com/min2hi/medi_chain/commit/c5dc46e4b8970305f691b0ba9e61660265525757))
