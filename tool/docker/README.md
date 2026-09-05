# Linux bauen, ohne Linux

```bash
docker build -f tool/docker/linux.Dockerfile -t preppsuite-linux tool/docker
docker run --rm -v "$PWD:/src:ro" preppsuite-linux bash -lc '
  cp -r /src /work && cd /work
  rm -rf preppsuite_flutter/build .dart_tool preppsuite_flutter/.dart_tool
  git config --global --add safe.directory /work
  flutter pub get
  cd preppsuite_flutter && flutter build linux --release'
```

Kopiert wird ins Bild hinein statt hinein gemountet, damit der Linux-Bau
nicht in dasselbe `build/` schreibt wie der vom Mac. Auf Apple-Silicon
kommt **arm64** heraus; ein x64-Paket zum Weitergeben macht die CI
(`.github/workflows/build-desktop.yml`).

Was auf einer echten Maschine gebraucht wird, steht in
[`docs/desktop-bauen.md`](../../docs/desktop-bauen.md).
