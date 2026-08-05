{ pkgs, lib, ... }:
let
  ctx = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ctx";
    version = "0.24.0";
    src = pkgs.fetchFromGitHub {
      owner = "ctxrs";
      repo = "ctx";
      rev = "v${version}";
      hash = "sha256-ctlDglcgUA34qxsOGxLktUS6cLUK0wMcnb3HrHjyz3Y=";
    };
    cargoHash = "sha256-868tSR3GjN/WvYHG738iBW0VwxnhndUxZ7fSo7OsFzo=";
    # workspace には ctx-cli 以外に複数 crate があるが、home.packages に載せたいのは
    # `ctx` バイナリ本体（crates/ctx-cli）のみ
    cargoBuildFlags = [ "-p" "ctx" ];

    # ctx-cli の fastembed は ort-download-binaries-* を有効にしており、ort-sys の
    # build script が ONNX Runtime の prebuilt をビルド中にダウンロードする。NixOS は
    # sandbox = true のためこれが名前解決に失敗して落ちる（macOS の Nix は既定で
    # サンドボックスが無効なため、たまたま通っていた）。
    # ORT_LIB_LOCATION を設定すると build script はダウンロード分岐へ進まず、そこにある
    # ライブラリへリンクする。ただし既定は静的リンクで、nixpkgs の onnxruntime は共有
    # ライブラリしか持たないため ORT_PREFER_DYNAMIC_LINK=1 も要る（未指定だと
    # "could not link to the ONNX Runtime build in ..." で落ちる）。
    # 値は `-L native=` にそのまま渡るので lib ディレクトリを直接指す。
    # feature を変えないので Cargo.lock・vendor・cargoHash は不変。
    # （ort-load-dynamic への差し替えは libloading が vendor に無く offline 解決に失敗する）
    ORT_LIB_LOCATION = "${pkgs.onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";

    # rusqlite の bundled feature が sqlite を C ソースからビルドするため cc が要る
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.onnxruntime ];

    doCheck = false;
  };
in
{
  home.packages = [ ctx ];
}
