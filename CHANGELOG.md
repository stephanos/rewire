# Changelog

## [0.9.0] - 2022-10-02

### Added

- added code coverage

## [0.8.0] - 2021-11-13

### Added

- added ability to re-rewire a module attribute

## [0.7.0] - 2020-11-07

### Added

- added ability to re-rewire a module
- added extensive debug logging

## [0.6.0] - 2020-11-06

### Added

- support for rewiring a dependency on an Erlang module

## [0.5.4] - 2020-10-31

### Changed

- fixed bug for references to a previously-defined inner module

## [0.5.3] - 2020-10-17

### Changed

- docs and tests to use `import` instead of `use`

## [0.5.2] - 2020-10-17

### Changed

- improved documentation

## [0.5.1] - 2020-10-17

### Added

- improved compiler errors

## [0.5.0] - 2020-10-17

### Added

- support for rewiring nested modules

## [0.4.1] - 2020-10-12

### Added

- added mix formatter export

## [0.4.0] - 2020-10-07

### Added

- added debug option

## [0.3.3] - 2020-10-06

### Changed

- internal refactorings
- improved documentation

## [0.3.2] - 2020-10-02

### Changed

- support `as` for `rewire` block

## [0.3.1] - 2020-10-02

### Added

- Elixir module documentation

## [0.3.0] - 2020-10-01

### Added

- module-scoped `rewire`

## [0.2.1] - 2020-09-30

### Changed

- improved alias detection of caller module

## [0.2.0] - 2020-09-30

### Changed

- moved all code generation to compile-time due to compiler warnings in Elixir 1.10+

## [0.1.1] - 2020-09-30

### Changed

- fixed deprecation warning in Elixir 1.10+

## [0.1.0] - 2020-09-28

### Added

- initial version
- `rewire` with module args
- `rewire` with shorthand args
- error for non-existant module
- error for missing module replacement
