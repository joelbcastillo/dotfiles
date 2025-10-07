# Templates Directory

This directory contains templates for customizing your dotfiles setup.

## How to Use Templates

### Customizing Profiles

1. **Copy a Profile**: Copy either the `minimal` or `full` profile from `.dotbot/profiles/` to this directory.
2. **Modify the Profile**: Edit the copied profile to add or remove configurations as needed.
3. **Install the Profile**: Use the install script to apply your customized profile:
   ```bash
   ./install profile your-custom-profile
   ```

### Adding New Configurations

1. **Create a New Template**: Add your new configuration files to the appropriate directory (e.g., `shells/`, `tools/`, etc.).
2. **Update the Profile**: Modify your profile to include the new configurations.
3. **Install the Profile**: Apply the updated profile using the install script.

## Best Practices

- **Keep Templates Clean**: Ensure templates are free of personal or sensitive data.
- **Document Changes**: Clearly document any changes or additions to the templates.
- **Test Thoroughly**: Test your customized profiles to ensure they work as expected.

By following these guidelines, you can easily customize and extend your dotfiles setup. 