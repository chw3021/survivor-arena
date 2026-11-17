# Survivor Arena

Vampire Survivors / 탕탕특공대 스타일 서바이벌 프로토타입.

- 엔진: **Godot 4.7**
- 목표: Steam(PC) + GitHub Pages 웹 플레이 테스트

## 조작

| 키 | 동작 |
|---|---|
| WASD | 이동 |
| 방향키 | 공격 |
| Space | 대시 (무적 프레임) |
| Q | 무기 변경 (Slash / Bolt) |
| E | 액티브 (주변 피해) |
| R | 사망 후 재시작 |

## 로컬 실행

1. Godot 4.7.x로 이 폴더를 Import / Open
2. F5 (Play)

CLI:

```bash
godot --path . 
```

## GitHub Pages

- 사이트: https://chw3021.github.io/survivor-arena/
- 플레이: https://chw3021.github.io/survivor-arena/play.html
- 설계 문서: https://chw3021.github.io/survivor-arena/docs/

`main` 푸시 시 Godot Web export + `site/` 허브·문서를 함께 배포한다.

로컬 Web export (export template 필요):

```powershell
./scripts/deploy-web.ps1
```

```bash
bash scripts/deploy-web.sh
# 또는
godot --headless --path . --export-release "Web" build/web/index.html
```

## 폴더

```
scenes/     메인·플레이어·적·HUD
scripts/    게임 로직
site/       GitHub Pages 허브·설계 문서 (HTML)
build/      export 결과 (gitignore)
```

캐릭터/몬스터/UI는 임시 도형·라벨이다. 아트·밸런스는 이후 교체하면 된다.
