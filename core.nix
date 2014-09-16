
let
  inherit (import ./lib) listToAttrs nameValuePair;

  imports = [ "PATH" "SSH_AUTH_SOCK" "GIT_ALTERNATE_OBJECT_DIRECTORIES" ];
  env = listToAttrs (map (p: nameValuePair p (builtins.getEnv p)) imports);

  unsafeDerivation = args: derivation ({
    PATH = "/bin:/usr/bin:/usr/local/bin:/run/current-system/sw/bin";
    system = builtins.currentSystem;
    builder = ./proxy-bash.sh;
    preferLocalBuild = true;
    __noChroot = true;
  } // args);

in rec {
  inherit env;

  writeText = name: text: unsafeDerivation {
    inherit name;
    args = ["-c" "echo -n '${text}' > $out"];
  };

  dummy = writeText "dummy" "dummy";

  decrypt = file: shell (builtins.baseNameOf (builtins.toString file)) ''
    gpg --use-agent --no-tty --decrypt \${toString file} > \$out
  '';
 
  shell = name: command: unsafeDerivation {
    inherit name; 
    args = ["-c" command];
  };

  fetchurl = url: shell (baseNameOf (toString url)) ''
    curl --location --max-redirs 20 --retry 3 -o $out ${url}
  '';

  fetchgit =
    {url, rev ? "origin/master"}:
      shell (baseNameOf (toString url)) ''
        mkdir -p $out
        cd $out
        git init .
        git remote add origin ${url}
        git fetch -tu origin
        git checkout -b fetchgit ${rev}
        git submodule init && git submodule update
      '';
}
