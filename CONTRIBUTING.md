# Contributing

Thanks for helping improve Speed.

## Before You Open a PR

- Branch from `main`
- Keep the change focused and small when possible
- Run `swift test`
- Run `./scripts/build-app.sh` if you touched app behavior or UI

## PR Expectations

- Open the pull request against `main`
- Add a short summary of what changed
- List the testing you ran
- Include screenshots for visible UI changes

Store repository screenshots in `docs/images/`.
Use `menu-popover.png` for the menu bar popover and `settings-window.png` for the settings window.

The GitHub Actions workflow will run tests and build the app bundle for every PR to `main`.
