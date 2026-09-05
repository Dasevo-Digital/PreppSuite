# Linux bauen, ohne Linux

Entwickelt wird auf einem Mac, ausgeliefert werden soll auch nach Linux.
Damit der Linux-Bau nicht erst in der CI auffällt, geht er hier lokal im
Container.

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
nicht in dasselbe `build/` schreibt wie der vom Mac.

Auf Apple-Silicon kommt dabei ein **arm64**-Bau heraus. Für die
Fensterverwaltung und die Plugin-Verdrahtung ist das dasselbe; ein
x64-Paket zum Weitergeben macht die CI
(`.github/workflows/build-desktop.yml`).

Windows lässt sich von hier aus gar nicht bauen. Dafür gibt es nur die CI
oder eine echte Maschine.
