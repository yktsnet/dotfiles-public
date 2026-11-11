# 保証台帳の一覧

保証駆動開発（GDD）では、何が壊れてはいけないか（保証）を人が先に承認し、それを固定するテストと実装はエージェントが書く。承認した保証は各リポの保証台帳 `docs/guarantees/` に、裏付けるテストと一緒に積み上がる。考え方は [Zenn: 保証駆動開発](https://zenn.dev/yktsnet/articles/202608-guarantee-driven-development) と [README の GDD の段落](../README.md#1-守る約束を先に書く) にある。この一覧は `.github/scripts/guarantees-showcase.sh` が週1回書き出すもので、手で直さない。

| リポ | 保証 | 対象ファイル | Gaps | 状態 | 最終更新 |
|---|---:|---:|---:|---|---|
| [cat-feed-tracker](https://github.com/yktsnet/cat-feed-tracker/tree/main/docs/guarantees) | 26 | 5 | 0 | 正式 | 2026-11-11 |
| [ccreel](https://github.com/yktsnet/ccreel/tree/main/docs/guarantees) | 153 | 6 | 0 | 正式 | 2026-11-11 |
| [codeview](https://github.com/yktsnet/codeview/tree/main/docs/guarantees) | 156 | 8 | 0 | 正式 | 2026-11-11 |
| [drip-sim-public](https://github.com/yktsnet/drip-sim-public/tree/main/docs/guarantees) | 310 | 20 | 0 | 正式 | 2026-11-11 |
| [etax-prep](https://github.com/yktsnet/etax-prep/tree/main/docs/guarantees) | 69 | 4 | 0 | 正式 | 2026-11-11 |
| [excel-kanri](https://github.com/yktsnet/excel-kanri/tree/main/docs/guarantees) | 73 | 6 | 0 | 正式 | 2026-11-11 |
| [folio-agent](https://github.com/yktsnet/folio-agent/tree/main/docs/guarantees) | 167 | 18 | 0 | 正式 | 2026-11-11 |
| [mgmt-kit](https://github.com/yktsnet/mgmt-kit/tree/main/docs/guarantees) | 162 | 10 | 0 | 正式 | 2026-11-11 |
| [nfc-attendance-kit](https://github.com/yktsnet/nfc-attendance-kit/tree/main/docs/guarantees) | 75 | 3 | 0 | 正式 | 2026-11-11 |
| [portfolio-astro](https://github.com/yktsnet/portfolio-astro/tree/main/docs/guarantees) | 22 | 3 | 0 | 正式 | 2026-11-11 |
| [tg-dev-digest](https://github.com/yktsnet/tg-dev-digest/tree/main/docs/guarantees) | 37 | 5 | 0 | 正式 | 2026-11-11 |
| [training-scheduler](https://github.com/yktsnet/training-scheduler/tree/main/docs/guarantees) | 59 | 7 | 0 | 正式 | 2026-11-11 |
| **合計（12 リポ）** | **1309** | **95** | **0** | | |
