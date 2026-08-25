# WeHive Shared Libraries

This directory contains shared libraries and modules used across all WeHive projects.

## Structure

```
.commons/lib/
└── wehive/              # WeHive CLI modules
    ├── helpers.sh       # Environment loading
    ├── cloudflare.sh    # Cloudflare DNS management
    ├── completions.sh   # Bash/Zsh completions
    └── core.sh          # Main CLI router
```

## wehive CLI

The WeHive CLI is built by combining all modules in `lib/wehive/` into a single executable.

**Installation**: See [../bootstrap/wehive/README.md](../bootstrap/wehive/README.md)

**Build process**:
1. `.commons/bootstrap/wehive/install.sh` runs
2. Combines all `lib/wehive/*.sh` modules
3. Installs to `/usr/local/bin/wehive`
4. Sets up bash/zsh completion

## Adding New CLI Modules

To add a new module to the wehive CLI:

1. Create module file in `lib/wehive/`:
   ```bash
   touch .commons/lib/wehive/mymodule.sh
   ```

2. Implement module following the pattern:
   ```bash
   #!/bin/bash
   # WeHive MyModule
   # Command: wehive mymodule <args>

   wehive_mymodule() {
       local subcommand="$1"
       shift

       case "$subcommand" in
           action1)
               wehive_mymodule_action1 "$@"
               ;;
           *)
               echo "Unknown subcommand: $subcommand" >&2
               echo "Available: action1" >&2
               return 1
               ;;
       esac
   }

   wehive_mymodule_action1() {
       echo "Executing action1..."
   }

   # Setup alias (optional)
   alias mm='wehive mymodule'
   ```

3. Update `bootstrap/wehive/install.sh` to include your module:
   ```bash
   echo "   Including mymodule.sh..."
   tail -n +2 "$LIB_DIR/mymodule.sh" >> "$TEMP_FILE"
   ```

4. Update `lib/wehive/completions.sh` for tab completion:
   ```bash
   1)
       COMPREPLY=($(compgen -W "helpers cloudflare mymodule help" -- "$cur"))
       ;;
   2)
       case "$cmd" in
           mymodule)
               COMPREPLY=($(compgen -W "action1" -- "$cur"))
               ;;
   ```

5. Update `lib/wehive/core.sh` router:
   ```bash
   case "$command" in
       # ... existing cases
       mymodule)
           wehive_mymodule "$@"
           ;;
   ```

6. Reinstall CLI:
   ```bash
   .commons/bootstrap/wehive/install.sh
   ```

## Module Best Practices

1. **Auto-load environment**: Modules can access `$WEHIVE_ENV_LOADED` and `$PROJECT_ROOT`
2. **Idempotent**: Use helpers like `wehive_helpers_env_load` which are idempotent
3. **Clear errors**: Always provide helpful error messages
4. **Validation**: Check for required tools and credentials
5. **Examples**: Include usage examples in error messages

## Testing Modules

Test new modules locally before installing:

```bash
# Build locally without installing
cat lib/wehive/{helpers,cloudflare,mymodule,completions,core}.sh > /tmp/wehive-test
chmod +x /tmp/wehive-test

# Test
/tmp/wehive-test mymodule action1
```
