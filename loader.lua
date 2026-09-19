shared.Rooze = {
    ['Settings'] = {
        ['Team Check'] = true,
        ['Knock Check'] = true,
        ['Visible Check'] = false,
    },
    ['Keybinds'] = {
        ['Trigger Bot'] = { ['Key'] = 'T', ['Mode'] = 'Toggle' },
    },
    ['Trigger Bot'] = {
        ['Enabled'] = true,
        ['Delay'] = 0.01,
        ['Specific Weapons'] = {
            ['Enabled'] = false,
            ['Weapons'] = { '[Double-Barrel SG]', '[Revolver]', '[TacticalShotgun]' },
        },
    },
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/aisjhfiashfnaijf/tb/refs/heads/main/triggerbot.lua"))()
