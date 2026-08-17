{ dimunyx-qs, wall-archive }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.dimunyx-qs;

  patchedConfig = pkgs.runCommandLocal "dimunyx-qs-config" {
    nativeBuildInputs = [ pkgs.gnused ];
  } ''
    cp -r ${cfg.package}/share/dimunyx-qs $out
    chmod -R +w $out

    sed -i "s|programs.dimunyx-qs.password|\"${cfg.password}\"|g" "$out/Services/Lockscreen.qml"

    ${if cfg.weather.enable then ''
      sed -i 's|@WEATHER_API_KEY@|${cfg.weather.key}|' "$out/Indicators/Clock.qml"
      sed -i 's|@WEATHER_CITY@|${if cfg.weather.city == "" then "Chisinau" else cfg.weather.city}|' "$out/Indicators/Clock.qml"
      sed -i '/\/\/ WEATHER_BLOCK/d' "$out/Indicators/Clock.qml"
      sed -i '/\/WEATHER_BLOCK/d' "$out/Indicators/Clock.qml"
    '' else ''
      sed -i '/\/\/ WEATHER_BLOCK/,/\/WEATHER_BLOCK/d' "$out/Indicators/Clock.qml"
    ''}

    ${lib.optionalString (cfg.locale != "en_US") ''
      sed -i 's|property string locale: "en_US"|property string locale: "${cfg.locale}"|' "$out/Services/Translation.qml"
    ''}

    ${lib.optionalString (!cfg.enableWallpapers) ''
      sed -i 's|^\(\s*\)Wallpaper {}|\1//Wallpaper {}|' "$out/Bar.qml"
    ''}
  '';
in {
  options.programs.dimunyx-qs = {
    enable = lib.mkEnableOption "dimunyx-qs quickshell bar";

    package = lib.mkOption {
      type = lib.types.package;
      default = dimunyx-qs;
      defaultText = lib.literalMD "`dimunyx-qs` package from flake";
      description = "The dimunyx-qs package to use.";
    };

    enableWallpapers = lib.mkEnableOption "wall-archive wallpapers in ~/.config/wallpapers";

    weather = {
      enable = lib.mkEnableOption "weather display in clock indicator";
      key = lib.mkOption {
        type = lib.types.str;
        default = "1111";
        description = "OpenWeatherMap API key for weather data.";
      };
      city = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "City for weather display.";
      };
    };

    locale = lib.mkOption {
      type = lib.types.enum ["en_US" "ru_RU" "ro_RO"];
      default = "en_US";
      example = "ru_RU";
      description = "Locale for translations: en_US, ru_RU, or ro_RO.";
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Password for lock screen authentication.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cfg.package
      brightnessctl
      playerctl
      cliphist
      wl-clipboard
      cava
      lm_sensors
      power-profiles-daemon
      bluez
    ];

    home.sessionVariables = {
      QUICKSHELL_PASSWORD = cfg.password;
    };

    xdg.configFile."quickshell" = {
      source = patchedConfig;
      recursive = true;
    };

    xdg.configFile."wallpapers" = lib.mkIf cfg.enableWallpapers {
      source = wall-archive.outPath;
      recursive = true;
    };
  };
}
