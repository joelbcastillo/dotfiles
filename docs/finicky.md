# Finicky Configuration

This document describes the Finicky browser router configuration included in this dotfiles setup.

## Overview

Finicky is a macOS application that intelligently routes URLs to different browsers based on customizable rules. This configuration automatically routes links from Microsoft Teams and Outlook to Microsoft Edge with your domain account profile, ensuring seamless SSO and maintaining authentication context for Microsoft 365 services.

## Configuration File

The Finicky configuration is stored in your **private dotfiles repository** at `~/.dotfiles-private/tools/finicky/finicky.js`. This ensures your Edge profile information remains private.

A template file is available in the public repository at `tools/finicky/finicky.js.template` for reference.

## Key Features

### Default Browser
- **Safari**: Set as the default browser for all other links
- You can change this to Chrome, Firefox, or any other browser

### Microsoft Teams & Outlook Routing
- **Source Detection**: Detects when links are clicked from:
  - Microsoft Teams (`com.microsoft.teams`)
  - Microsoft Outlook (`com.microsoft.Outlook`)
  - Office 365 Service (`com.microsoft.Office365ServiceV2`)

- **URL Pattern Matching**: Routes Microsoft URLs including:
  - `teams.microsoft.com`
  - `outlook.office.com` and `outlook.live.com`
  - `*.sharepoint.com`
  - `*.office.com` and `*.office365.com`
  - `*.microsoft.com`

- **Edge Profile**: Opens links in Microsoft Edge with a specific profile directory
  - Default: `Profile 1` (you need to update this to match your profile)

## Installation

### Step 1: Install Finicky
Finicky is included in your `Brewfile` and will be installed automatically when you run:
```bash
brew bundle
```

Or install manually:
```bash
brew install --cask finicky
```

### Step 2: Set Up Configuration
```bash
# First, ensure private files are set up
./install private

# Then install Finicky configuration
./install config finicky
```

### Step 3: Find Your Edge Profile Directory

1. Open Microsoft Edge with your domain/work account profile
2. Navigate to `edge://version/` in the address bar
3. Look for the **"Profile Path"** field
4. Note the directory name (e.g., `Profile 1`, `Default`, `Profile 2`, etc.)

Example Profile Path:
```
Profile Path: /Users/yourname/Library/Application Support/Microsoft Edge/Profile 1
```
The profile directory name is `Profile 1` in this case.

### Step 4: Configure Your Profile

1. If you haven't already, copy the template to your private repository:
   ```bash
   mkdir -p ~/.dotfiles-private/tools/finicky
   cp ~/.dotfiles/tools/finicky/finicky.js.template ~/.dotfiles-private/tools/finicky/finicky.js
   ```

2. Edit `~/.dotfiles-private/tools/finicky/finicky.js` and update the `--profile-directory` argument:

```javascript
browser: {
  name: "Microsoft Edge",
  args: [
    "--profile-directory=Profile 1"  // Replace with your actual profile name
  ]
}
```

### Step 5: Enable Finicky

1. Open Finicky from Applications
2. Finicky will appear in your menu bar
3. Click the Finicky icon and select "Set as Default Browser"
4. macOS will prompt you to set Finicky as the default browser in System Settings

### Step 6: Verify Configuration

1. Open Microsoft Teams or Outlook
2. Click on a link (e.g., a SharePoint link or Office 365 link)
3. The link should open in Microsoft Edge with your domain account profile
4. Verify you're logged in with the correct account

## Configuration Details

The configuration includes two handlers for maximum coverage:

1. **Source-based routing**: Detects links from Microsoft apps (Teams, Outlook)
2. **URL-based routing**: Catches Microsoft URLs even if not from Teams/Outlook

### Customization Options

#### Change Default Browser
```javascript
module.exports = {
  defaultBrowser: "Google Chrome",  // or "Firefox", "Safari", etc.
  // ...
};
```

#### Add More URL Patterns
```javascript
{
  match: [
    "https://teams.microsoft.com/*",
    "https://your-custom-domain.com/*",  // Add custom patterns
  ],
  browser: {
    name: "Microsoft Edge",
    args: ["--profile-directory=Profile 1"]
  }
}
```

#### Route Specific Apps to Different Browsers
```javascript
{
  match: ({ sourceBundleIdentifier }) => {
    return sourceBundleIdentifier === "com.slack.Slack";
  },
  browser: "Google Chrome"  // Open Slack links in Chrome
}
```

#### Use Multiple Edge Profiles
```javascript
{
  match: ({ url }) => {
    // Work URLs go to work profile
    return /work-domain\.com/.test(url);
  },
  browser: {
    name: "Microsoft Edge",
    args: ["--profile-directory=Profile 1"]  // Work profile
  }
},
{
  match: ({ url }) => {
    // Personal URLs go to personal profile
    return /personal-domain\.com/.test(url);
  },
  browser: {
    name: "Microsoft Edge",
    args: ["--profile-directory=Default"]  // Personal profile
  }
}
```

## Troubleshooting

### Links Not Opening in Edge

1. **Check Finicky is Running**
   - Look for the Finicky icon in your menu bar
   - If missing, open Finicky from Applications

2. **Verify Default Browser Setting**
   - System Settings → Desktop & Dock → Default web browser
   - Should be set to "Finicky"

3. **Check Profile Directory**
   - Verify the profile name in `~/.dotfiles-private/tools/finicky/finicky.js` matches your actual Edge profile
   - Open Edge and go to `edge://version/` to confirm
   - Run `./install config finicky` to update the symlink after changes

4. **Test Configuration**
   - Open Finicky menu → "Test Configuration"
   - Check for any JavaScript errors

### Edge Opens with Wrong Profile

- Update the `--profile-directory` argument in `~/.dotfiles-private/tools/finicky/finicky.js`
- Make sure you're using the correct profile directory name
- Run `./install config finicky` to update the symlink
- Restart Finicky after making changes

### Links Still Open in Default Browser

- Ensure Finicky is set as the default browser in System Settings
- Some apps (like Slack) may have their own browser settings that override system defaults
- Check app-specific settings for Teams/Outlook

### Debugging

Enable logging in `~/.dotfiles-private/tools/finicky/finicky.js`:
```javascript
module.exports = {
  // ... your config
  options: {
    logRequests: true  // Log all routing decisions
  }
};
```

Then check the Finicky logs:
- Open Finicky menu → "Show Logs"
- Or check Console.app for Finicky messages

## Benefits

- **Microsoft 365 Integration**: SharePoint, Office 365, and Teams links automatically open in Edge with your work profile
- **SSO Support**: Maintains Microsoft SSO context—no re-authentication needed when opening links
- **Account Separation**: Work links use Edge work profile, personal links use your default browser
- **Seamless Experience**: Links from Teams/Outlook automatically route to the correct browser and profile without manual intervention

## Additional Resources

- [Finicky Documentation](https://github.com/johnste/finicky)
- [Finicky Configuration Examples](https://github.com/johnste/finicky/wiki/Configuration-examples)
- [Microsoft Edge Profile Management](https://support.microsoft.com/en-us/microsoft-edge/manage-profiles-in-microsoft-edge-2491098e-273c-0e1e-6d5b-93b0bfde1e5f)

## Best Practices

1. **Update Profile Names**: If you create new Edge profiles, update the configuration in your private repo
2. **Test After Changes**: Always test routing after modifying the configuration
3. **Version Control**: Your config is in your private repository, so changes are tracked
4. **Document Custom Rules**: Add comments in the config file explaining custom routing logic
5. **Keep Updated**: Run `brew upgrade finicky` regularly for latest features and bug fixes
