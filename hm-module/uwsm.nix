{ lib, ... }:
{ config, ... }:
let
  cfg = config.programs.uwsm;

  hmSessionVars =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
in {
  options = {
    programs.uwsm = {
      env = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Shell script lines to write to `$XDG_CONFIG_HOME/uwsm/env` to bootstrap environment.
        '';
      };
      sourceSessionVariables = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to link Home Manager's session variables script
          (`hm-session-vars.sh`) to `$XDG_CONFIG_HOME/uwsm/env`.

          It is highly recommended to enable this option if you are using the UWSM
          NixOS module.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.env != "") { xdg.configFile."uwsm/env".text = cfg.env; })
    (lib.mkIf (cfg.env != "" && cfg.sourceSessionVariables) {
      xdg.configFile."uwsm/env".text = lib.mkOrder 200 ''
        source ${hmSessionVars}
      '';
    })
    (lib.mkIf (cfg.env == "" && cfg.sourceSessionVariables) {
      xdg.configFile."uwsm/env".source = hmSessionVars;
    })
  ];
}
