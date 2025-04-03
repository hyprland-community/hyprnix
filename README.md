# Hyprnix

> **WORK IN PROGRESS** - Feel free to browse the source code, obscure things should have comments.

This flake was `filter-repo`'d out from [spikespaz/dotfiles].

~~We have yet to determine a permanent home for this code.
See [this issue comment](https://github.com/hyprland-community/hyprnix/issues/1)
for an explanation.~~

Endorsed by other Nix users, but I have to finish it.

## Usage

Add the flake as an input to your own.

```nix
{
    inputs = {
        hyprnix.url = "github:hyprland-community/hyprnix";
        # ...
    };
    # ...
}
```

Assuming that you know Nix well enough to have your flake's `inputs` passed
around to your Home Manager configuration, you can use the module in `imports`
somewhere.

```nix
{ lib, pkgs, inputs, ... }: {
    imports = [ inputs.hyprnix.homeManagerModules.default ];

    wayland.windowManager.hyprland = {
        enable = true;
        reloadConfig = true;
        systemdIntegration = true;
        # recommendedEnvironment = false;
        # nvidiaPatches = true;

        config = {
            # ...
        };
        # ...
    };
    # ...
}
```

## Documentation

Because there is no documentation for module options yet, it is recommended to
browse others' configurations as examples.

- [@spikespaz/dotfiles](https://github.com/spikespaz/dotfiles/tree/master/users/jacob/hyprland)

Remember that these are personal configurations,
which is under constant revision, so it may be a mess at times.

<!-- LINKS -->

[hyprwm/hyprland]: https://github.com/hyprwm/hyprland
[spikespaz/dotfiles]: https://github.com/spikespaz/dotfiles
