# Finicky Configuration

This document describes the Finicky browser router configuration included in this dotfiles setup.

## Overview

Finicky is a macOS application that intelligently routes URLs to different browsers based on customizable rules. This configuration automatically routes links from Microsoft Teams and Outlook to Microsoft Edge with your domain account profile, ensuring seamless SSO and maintaining authentication context for Microsoft 365 services.

## Configuration File

The Finicky configuration is stored in your **private dotfiles repository** at `~/.dotfiles-private/tools/finicky/finicky.js`. This ensures your Edge profile information remains private.

A template file is available in the public repository at `tools/finicky/finicky.js.template` for reference.

## Key Features

### API Version
This configuration uses the **Finicky v4 API** where:
- The first argument to `match`/`browser` functions is the URL instance (a standard [URL object](https://developer.mozilla.org/en-US/docs/Web/API/URL))
- The second argument contains context (`sourceBundleIdentifier`, `opener`, etc.)
- When using custom `args` in the browser config, you must explicitly include the URL

See [Finicky v4 Migration Guide](https://github.com/johnste/finicky/discussions/378) for details.

### Default Browser
- **Google Chrome**: Set as the default browser for all other links
- You can change this to Safari, Firefox, or any other browser

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
  - `*.teams.cdn.office.net` (Microsoft Safe Links)
  - `*.safelinks.protection.outlook.com` (Microsoft Safe Links)

- **Edge Profile**: Opens links in Microsoft Edge with a specific profile directory
  - Uses the EdgeProfile helper app to work around macOS limitations (see below)

### EdgeProfile Helper App

On macOS, Microsoft Edge ignores the `--profile-directory` command-line argument when the browser is already running—it just activates the existing window without opening the URL. To work around this, we use a small AppleScript wrapper app called **EdgeProfile** that uses `open -na` to force Edge to respect the profile argument.

The EdgeProfile app source is at `tools/finicky/EdgeProfile.applescript`.

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

### Step 2: Build the EdgeProfile Helper App

The EdgeProfile app is required to properly open URLs in Edge with a specific profile on macOS.

1. First, find your Edge profile directory name (see Step 3 below)

2. Edit the profile name in the AppleScript source:
   ```bash
   # Edit tools/finicky/EdgeProfile.applescript
   # Change the line: property profileDir : "Profile 1"
   # to use your actual profile directory name
   ```

3. Compile the AppleScript into an app:
   ```bash
   mkdir -p ~/Applications
   osacompile -o ~/Applications/EdgeProfile.app ~/.dotfiles/tools/finicky/EdgeProfile.applescript
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

### Step 4: Set Up Finicky Configuration

1. Ensure private files are set up:
   ```bash
   ./install private
   ```

2. Copy the template to your private repository:
   ```bash
   mkdir -p ~/.dotfiles-private/tools/finicky
   cp ~/.dotfiles/tools/finicky/finicky.js.template ~/.dotfiles-private/tools/finicky/finicky.js
   ```

3. Install the Finicky configuration symlink:
   ```bash
   ./install config finicky
   ```

The template uses `browser: "EdgeProfile"` which references the helper app you built in Step 2. The Edge profile is configured in the AppleScript, not in the Finicky config.

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
  browser: "EdgeProfile"  // Uses the EdgeProfile helper app
}
```

#### Route Specific Apps to Different Browsers
```javascript
{
  // Finicky v4 API: url is first arg, context (sourceBundleIdentifier) is second arg
  match: (url, { sourceBundleIdentifier }) => {
    return sourceBundleIdentifier === "com.slack.Slack";
  },
  browser: "Google Chrome"  // Open Slack links in Chrome
}
```

#### Use Multiple Edge Profiles

To use multiple Edge profiles, create separate EdgeProfile apps for each profile:

1. Copy and modify the AppleScript for each profile:
   ```bash
   # Create EdgeProfileWork.applescript with profileDir: "Profile 1"
   # Create EdgeProfilePersonal.applescript with profileDir: "Default"
   ```

2. Compile each into a separate app:
   ```bash
   osacompile -o ~/Applications/EdgeProfileWork.app EdgeProfileWork.applescript
   osacompile -o ~/Applications/EdgeProfilePersonal.app EdgeProfilePersonal.applescript
   ```

3. Use them in your Finicky config:
   ```javascript
   {
     match: (url) => /work-domain\.com/.test(url.href),
     browser: "EdgeProfileWork"
   },
   {
     match: (url) => /personal-domain\.com/.test(url.href),
     browser: "EdgeProfilePersonal"
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

- Update the `profileDir` property in `~/.dotfiles/tools/finicky/EdgeProfile.applescript`
- Recompile the app: `osacompile -o ~/Applications/EdgeProfile.app ~/.dotfiles/tools/finicky/EdgeProfile.applescript`
- Restart Finicky after making changes

### Edge Activates But URL Doesn't Open

This usually means the EdgeProfile helper app isn't installed or configured correctly:

1. Verify the app exists: `ls ~/Applications/EdgeProfile.app`
2. Test it manually: `open -a ~/Applications/EdgeProfile.app "https://example.com"`
3. If it doesn't work, recompile: `osacompile -o ~/Applications/EdgeProfile.app ~/.dotfiles/tools/finicky/EdgeProfile.applescript`

### "Accessing legacy property 'url'" Warning

If you see this warning in Finicky logs:
```
[WARN] Accessing legacy property "url" that is no longer supported
```

Your config is using the **old Finicky v3 API**. In v4, the function signature changed:
- **Old (v3)**: `match: ({ sourceBundleIdentifier, url }) => { ... }`
- **New (v4)**: `match: (url, { sourceBundleIdentifier }) => { ... }`

Update your config to use the v4 API as shown in the template.

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
