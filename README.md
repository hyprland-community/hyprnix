# Unofficial Hyprland Flake

> **WORK IN PROGRESS**

This flake was `filter-repo`'d out from [spikespaz/dotfiles].

We have yet to determine a permanent home for this code.
See [this issue comment](https://github.com/spikespaz/hyprland-nix/issues/1)
for an explanation.

## Usage

Add the flake as an input to your own.

```nix
{
    inputs = {
        # The name `hyprland-nix` is used for *this* flake.
        hyprland-nix.url = "github:spikespaz/hyprland-nix";
        # ...
    };
    # ...
}
```

The flakes from the `hyprwm` organization are included as inputs to allow them
to be easily overridden. You can set `.follows` to track one of your own inputs.

This can be useful in several situations. One reason you might want to do this
is if you want to lock each of these inputs independently, instead of waiting
for upstream repositories to update their own `flake.lock`.

Perhaps the most practical usage would be to use a different branch for Hyprland.
You can do this by appending the branch to the end of the URL, preceded by a `/`.

Here is a maximal example.

```nix
{
    inputs = {
        # This input for Hyprland explicitly tracks the `master` branch.
        # Feel free to change this as you need.
        hyprland-git.url = "github:hyprwm/hyprland/master";
        hyprland-xdph-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
        hyprland-protocols-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
        # This overrides each input for `hyprland-nix` to use the ones
        # specified above, which are locked by you.
        hyprland-nix.url = "github:spikespaz/hyprland-nix";
        hyprland-nix.inputs = {
            hyprland.follows = "hyprland-git";
            hyprland-xdph.follows = "hyprland-xdph-git";
            hyprland-protocols.follows = "hyprland-protocols-git";
        };
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
    imports = [ inputs.hyprland-nix.homeManagerModules.default ];

    wayland.windowManager.hyprland = {
        enable = true;
        reloadConfig = true;
        systemdIntegration = true;

        config = {
            # ...
        };
        # ...
    };
    # ...
}
```

## Updating

If you have adhered to the example in [Usage](#usage) for adding the two
necessary flake inputs, you can use the following command to update Hyprland
to the latest revision of the branch you have selected for `hyprland-git`.

```sh
nix flake lock --update-input hyprland-git
```

You can also update this flake separately. If you changed the name, remember to
adjust the following command accordingly.

```sh
nix flake lock --update-input hyprland-nix
```

## Documentation

Because there is no documentation for module options yet, it is recommended to
browse through @spikespaz's configuration.

<https://github.com/spikespaz/dotfiles/tree/master/users/jacob/desktops/hyprland>

Remember that this example is a personal configuration,
which is under constant revision, so it may be a mess at times.

<!-- LINKS -->

[hyprwm/hyprland]: https://github.com/hyprwm/hyprland
[spikespaz/dotfiles]: https://github.com/spikespaz/dotfiles
