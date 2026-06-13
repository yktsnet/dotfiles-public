{ pkgs }:
let
  getCommonPaths = home: [
    "${home}/dotfiles/apps/ops/lib"
    "${home}/dotfiles/apps/ops/core"
    "${home}/dotfiles/apps/ops2/lib"
    "${home}/dotfiles/apps/backtest/lib"
    "${home}/dotfiles/apps/backtest/core"
  ];
  notebooklm-py = pkgs.python3Packages.buildPythonApplication rec {
    pname = "notebooklm-py";
    version = "0.3.2";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "teng-lin";
      repo = "notebooklm-py";
      rev = "v0.3.2";
      hash = "sha256-TXaJbOfWklqDSrtWbZq1vaIMr+sCknfuSLYnfpI4QkU=";
    };
    postPatch = ''
      find src -type f -name "*.py" -exec sed -i 's/timeout=300/timeout=1800/g' {} +
      find src -type f -name "*.py" -exec sed -i 's/timeout=30/timeout=1800/g' {} +
      find src -type f -name "*.py" -exec sed -i 's/300\.0/1800.0/g' {} +
    '';
    build-system = with pkgs.python3Packages; [
      hatchling
      hatch-fancy-pypi-readme
    ];
    dependencies = with pkgs.python3Packages; [
      httpx
      click
      rich
      playwright
    ];
    doCheck = false;
  };
  notebooklm-wrapped = pkgs.symlinkJoin {
    name = "notebooklm";
    paths = [ notebooklm-py ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/notebooklm \
        --set PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers}
    '';
  };
in
{
  inherit notebooklm-wrapped;
  pythonPackages = ps: with ps; [
    pandas
    numpy
    requests
    pyyaml
    python-dateutil
    pytz
    pygments
    click
    certifi
    charset-normalizer
    idna
    urllib3
    six
    typing-extensions
    tzdata
    flask
    dash
    scipy
    scikit-learn
  ];
  makePythonPath = home: [
    "${home}/dotfiles/apps/ops"
    "${home}/dotfiles/apps/ops2"
    "${home}/dotfiles/apps/backtest"
  ] ++ (getCommonPaths home);
  commonEnv = home: appRoot: opsDataRoot: [
    "OPS_ROOT=${appRoot}"
    "OPS_DATA=${opsDataRoot}"
    "OPS_STATE_DIR=${opsDataRoot}/state"
    "PYTHONPATH=${builtins.concatStringsSep ":" ([ appRoot ] ++ (getCommonPaths home))}"
    "RESTIC_REPOSITORY=/mnt/ext_hdd/backups"
    "RESTIC_PASSWORD_FILE=/var/lib/sops/restic_password"
    "BACKUP_TARGETS=/home/yktsnet/ops_data,/home/yktsnet/dotfiles"
    "KEEP_DAILY=14"
  ];
}
