# Study Center Nias Android — Agent Instructions

This is a Flutter Android app (sc_student) for a study center / LMS in Nias, Indonesia.
Backend: Laravel/Sanctum at `studycenter.nanoprojectdevindonesia.com`.

## Design Review Rules

When reviewing or improving any UI/UX in this project, follow the design review process defined in:

- `~/.claude/skills/apple-design-skill/SKILL.md` — Full review methodology
- `~/.claude/skills/apple-design-skill/references/hig-lookup.md` — Topic-to-file mapping
- `~/.claude/skills/apple-design-skill/references/hig/` — 53 design guideline documents

### Quick Reference: Always Load These 4 Files First

```
~/.claude/skills/apple-design-skill/references/hig/accessibility.md
~/.claude/skills/apple-design-skill/references/hig/color.md
~/.claude/skills/apple-design-skill/references/hig/layout.md
~/.claude/skills/apple-design-skill/references/hig/typography.md
```

### Project-Specific Context

- **Framework**: Flutter (Android primary, target API 21+)
- **Language**: Indonesian (Bahasa Indonesia) for all UI strings
- **User base**: Students in Nias, Indonesia
- **Design target**: Mobile-first, clean and accessible UI
- **Touch targets**: Minimum 48dp (Material/Flutter standard, matching HIG's 44pt)
- **Navigation**: BottomNavigationBar for primary nav (not hamburger menus)
- **Colors**: Use semantic color tokens, not hardcoded hex values
- **Text**: Support font scaling (Flutter `textScaleFactor`)

### When to Load Extra References

| Situation | Extra files to load |
|-----------|-------------------|
| Form / input screen | `entering-data.md`, `keyboards.md` |
| Icons / images | `icons.md`, `images.md` |
| Onboarding / login | `onboarding.md`, `launching.md` |
| Loading / error states | `loading.md`, `feedback.md` |
| Notifications | `managing-notifications.md` |
| Account management | `managing-accounts.md` |
| Dark mode | `dark-mode.md`, `materials.md` |
| Gestures / swipe | `gestures.md` |

## Output Format

Always structure design reviews as:

```
## Design Review: [Screen/Feature]
### Summary
### Critical Issues (must fix)
### Improvements (should fix)
### Positive Notes
### Flutter-Specific Notes
```

Cite guidelines as: **Design Guideline — [topic]**: "..."
