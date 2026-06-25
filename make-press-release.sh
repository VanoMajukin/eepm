#!/bin/sh
# Generate a Telegram press release and image from an eepm release tag
# Usage: ./make-press-release.sh [--claude|--codex|--tool TOOL] [--mode MODE] [tag]
# Example: ./make-press-release.sh --codex --mode paste 3.64.55-alt1

SPECNAME="eepm.spec"
IMAGE_TEMPLATE="epm_update.svg"
TOOL="claude"
FORMAT_MODE="paste"
TAG=

usage()
{
    echo "Usage: $0 [--claude|--codex|--tool TOOL] [--mode paste|telegram-html] [tag]" >&2
    exit "${1:-1}"
}

cleanup()
{
    [ -z "$tmp_svg" ] || rm -f "$tmp_svg"
}

xml_warn_missing_font()
{
    if command -v fc-match >/dev/null 2>&1 ; then
        if ! fc-match Evolventa 2>/dev/null | grep -qi evolventa ; then
            echo "Warning: Evolventa font not found; install fonts-otf-evolventa or fonts-ttf-evolventa for the expected image look" >&2
        fi
    fi
}

xml_escape()
{
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

render_release_image()
{
    if [ ! -f "$IMAGE_TEMPLATE" ] ; then
        echo "Error: $IMAGE_TEMPLATE not found" >&2
        exit 1
    fi

    tmp_svg="$(mktemp "${TMPDIR:-/tmp}/epm-update.XXXXXX.svg")" || exit 1

    escaped_version="$(xml_escape "$version")"
    sed "s|>EPM [0-9][0-9.]*</tspan>|>EPM $escaped_version</tspan>|" "$IMAGE_TEMPLATE" > "$tmp_svg" || exit 1

    if ! grep -q ">EPM $escaped_version</tspan>" "$tmp_svg" ; then
        echo "Error: can't replace version in $IMAGE_TEMPLATE" >&2
        exit 1
    fi

    xml_warn_missing_font

    if command -v magick >/dev/null 2>&1 ; then
        if ! magick RSVG:"$tmp_svg" -background white -alpha remove -alpha off -quality 95 "$image_output" ; then
            echo "Error: failed to render JPG via ImageMagick; install ImageMagick-tools with RSVG support" >&2
            exit 1
        fi
    elif command -v convert >/dev/null 2>&1 ; then
        if ! convert RSVG:"$tmp_svg" -background white -alpha remove -alpha off -quality 95 "$image_output" ; then
            echo "Error: failed to render JPG via ImageMagick; install ImageMagick-tools with RSVG support" >&2
            exit 1
        fi
    else
        echo "Error: magick/convert command not found; install ImageMagick-tools with RSVG support" >&2
        exit 1
    fi

    if [ ! -s "$image_output" ] ; then
        echo "Error: image file '$image_output' was not created" >&2
        exit 1
    fi

    echo "Generated image: $image_output" >&2
}

build_prompt_text()
{
    case "$FORMAT_MODE" in
        paste)
            cat <<'PROMPT_END'
You are an expert at writing concise technical release posts in Russian for Telegram.

You will receive a changelog block from an RPM spec file for the "epm" package manager. Transform it into a Telegram-ready release post for manual copy-paste-send in a regular Telegram client.

FORMAT RULES:
- Output plain Telegram message text only. No HTML. No Markdown links.
- The result must be ready for this workflow: copy text, paste into Telegram, send.
- Do not rely on Bot API entities, parse modes, tg://emoji links, or other hidden formatting.
- Use the release version provided separately by the user, not a version from the changelog body.
- Start with exactly this title format:
  💾 Выпущена версия VERSION
- Leave one empty line between logical blocks.
- Use standard Unicode emoji only. Do not use custom emoji, animated emoji markup, sticker references, or placeholders.
- Render each command example as a fenced code block using triple backticks:
  ```
  command
  ```
- Use bullets with "• " for package lists, renames, removals, and descriptive changelog entries.
- Translate technical English changelog entries into clear, concise Russian.
- Drop internal implementation details that are not useful to users.
- For "eterbug #NNNNN" entries, mention only the app or feature name.
- Keep wording compact and close to the sample style.
- Keep the section order exactly as specified below.
- Do not add any intro, outro, signature, comment, or explanation outside the post body.
- If there are no matching entries for a section, omit the section completely.

ALWAYS INCLUDE THIS UPDATE BLOCK AFTER THE TITLE:
⬇️ Обновиться можно:

ALT Sisyphus/Ximper Linux:
```
epm upgrade
```

Стабильные бранчи ALT:
```
epm upgrade "https://download.etersoft.ru/pub/Korinf/x86_64/ALTLinux/p11/eepm-*.noarch.rpm"
```

Остальные системы:
```
epm ei
```

SECTION RULES:
- Use these section headers exactly:
  ➕ Новое в play:
  🔁 Переименовано:
  ⛔️ Удалено из play:
  📊 Улучшения в play:
  📊 Улучшения в repack:
  📊 Улучшения в pack:
  📊 Прочие улучшения:
- Keep only the sections that have matching entries, in exactly this order.
- In "Новое в play", list only new app names, one per line, formatted as "• app-name".
- Classify entries like "epm play: add APP" or "epm play: added APP" as "Новое в play".
- In "Переименовано", list package/app renames or replacements as "• old-name → new-name".
- Classify replacements like "replace old with new", "switch from old to new", or "removed because upstream replaced it" as "Переименовано".
- If a package was removed because it was replaced by another package, classify it as renamed/replaced, not deleted.
- In "Удалено из play", list only truly removed app names, one per line, formatted as "• app-name".
- Do not add descriptions in "Новое в play", "Переименовано", or "Удалено из play".
- In improvement sections, use "• app: краткое описание" when the entry is app-specific.
- Classify "epm play APP: ..." as "Улучшения в play".
- Classify "epm repack APP: ..." and "repack.d/..." as "Улучшения в repack".
- Classify "epm pack APP: ..." and "pack.d/..." as "Улучшения в pack".
- Put generic core changes (`epm`, `serv`, `distr_info`, repo logic, config loading, status, completions, shared pack/repack infrastructure) into "Прочие улучшения".
- Group closely related minor fixes into one bullet where that improves readability.
- Keep triple-backtick code fences exactly in the output.

Output ONLY the release post text, nothing else.
PROMPT_END
            ;;
        telegram-html)
            cat <<'PROMPT_END'
You are an expert at writing concise technical release posts in Russian for Telegram.

You will receive a changelog block from an RPM spec file for the "epm" package manager. Transform it into Telegram Bot API HTML.

FORMAT RULES:
- Output Telegram Bot API HTML only. No explanations. No Markdown.
- Use only Telegram-supported HTML entities and tags.
- Do not use custom emoji tags unless explicit emoji-id values were provided separately.
- Use the release version provided separately by the user, not a version from the changelog body.
- Start with exactly this title text:
  💾 Выпущена версия VERSION
- Leave one empty line between logical blocks.
- Render each command example as:
  <pre><code class="language-shell">...</code></pre>
- Render homogeneous app/package lists inside one <blockquote>...</blockquote>, one item per line.
- Use bullets with "• " only for descriptive changelog entries.
- Translate technical English changelog entries into clear, concise Russian.
- Drop internal implementation details that are not useful to users.
- For "eterbug #NNNNN" entries, mention only the app or feature name.
- Keep wording compact and close to the sample style.
- Keep the section order exactly as specified below.
- Do not add any intro, outro, signature, comment, or explanation outside the post body.
- Escape special HTML characters where needed.
- If there are no matching entries for a section, omit the section completely.

ALWAYS INCLUDE THIS UPDATE BLOCK AFTER THE TITLE:
⬇️ Обновиться можно:

ALT Sisyphus/Ximper Linux:
<pre><code class="language-shell">epm upgrade</code></pre>

Стабильные бранчи ALT:
<pre><code class="language-shell">epm upgrade "https://download.etersoft.ru/pub/Korinf/x86_64/ALTLinux/p11/eepm-*.noarch.rpm"</code></pre>

Остальные системы:
<pre><code class="language-shell">epm ei</code></pre>

SECTION RULES:
- Use these section headers exactly:
  ➕ Новое в play:
  🔁 Переименовано:
  ⛔️ Удалено из play:
  📊 Улучшения в play:
  📊 Улучшения в repack:
  📊 Улучшения в pack:
  📊 Прочие улучшения:
- Keep only the sections that have matching entries, in exactly this order.
- In "Новое в play", list only new app names in one blockquote, one per line, formatted as "• app-name".
- Classify entries like "epm play: add APP" or "epm play: added APP" as "Новое в play".
- In "Переименовано", list package/app renames or replacements in one blockquote as "old-name → new-name".
- Classify replacements like "replace old with new", "switch from old to new", or "removed because upstream replaced it" as "Переименовано".
- If a package was removed because it was replaced by another package, classify it as renamed/replaced, not deleted.
- In "Удалено из play", list only truly removed app names in one blockquote, one per line, formatted as "• app-name".
- Do not add descriptions in "Новое в play", "Переименовано", or "Удалено из play".
- In improvement sections, use "• app: краткое описание" when the entry is app-specific.
- Classify "epm play APP: ..." as "Улучшения в play".
- Classify "epm repack APP: ..." and "repack.d/..." as "Улучшения в repack".
- Classify "epm pack APP: ..." and "pack.d/..." as "Улучшения в pack".
- Put generic core changes (`epm`, `serv`, `distr_info`, repo logic, config loading, status, completions, shared pack/repack infrastructure) into "Прочие улучшения".
- Group closely related minor fixes into one bullet where that improves readability.

Output ONLY the HTML body text, nothing else.
PROMPT_END
            ;;
        *)
            echo "Error: unsupported mode '$FORMAT_MODE'" >&2
            exit 1
            ;;
    esac
}

tmp_svg=
trap cleanup EXIT HUP INT TERM

while [ $# -gt 0 ] ; do
    case "$1" in
        --claude|claude)
            TOOL="claude"
            ;;
        --codex|codex)
            TOOL="codex"
            ;;
        --tool)
            shift
            [ -n "$1" ] || usage
            case "$1" in
                claude|codex)
                    TOOL="$1"
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        --tool=claude)
            TOOL="claude"
            ;;
        --tool=codex)
            TOOL="codex"
            ;;
        --mode)
            shift
            [ -n "$1" ] || usage
            case "$1" in
                paste|telegram-html)
                    FORMAT_MODE="$1"
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        --mode=paste|--paste)
            FORMAT_MODE="paste"
            ;;
        --mode=telegram-html|--telegram-html)
            FORMAT_MODE="telegram-html"
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            usage
            ;;
        *)
            [ -z "$TAG" ] || usage
            TAG="$1"
            ;;
    esac
    shift
done

# find the latest release tag
[ -n "$TAG" ] || TAG="$(git tag -l '*-alt*' --sort=-version:refname | head -1)"

if [ -z "$TAG" ] ; then
    echo "Error: no release tag found" >&2
    exit 1
fi

if ! git rev-parse "$TAG" >/dev/null 2>&1 ; then
    echo "Error: tag '$TAG' not found" >&2
    exit 1
fi

version=$(printf '%s\n' "$TAG" | sed 's/-alt.*//')

echo "Using tag: $TAG" >&2

# Extract the latest changelog block from spec at the tag commit
specdata="$(git show "$TAG:$SPECNAME" 2>/dev/null)"
if [ -z "$specdata" ] ; then
    echo "Error: $SPECNAME not found at tag '$TAG'" >&2
    exit 1
fi

changelog_block=$(printf '%s\n' "$specdata" | sed -n '/^%changelog$/,/^$/{/^%changelog$/d;p}' | sed '/^$/q')

if [ -z "$changelog_block" ] ; then
    echo "Error: no changelog entries found in $SPECNAME" >&2
    exit 1
fi

image_output="epm-update-$version.jpg"

echo "Generating press release for epm $version ..." >&2
render_release_image

prompt_text=$(build_prompt_text)

prompt="$prompt_text

Use this release version: $version

Here is the changelog block to transform:
"

echo "Using tool: $TOOL" >&2
echo "Using mode: $FORMAT_MODE" >&2

if ! command -v "$TOOL" >/dev/null 2>&1 ; then
    echo "Error: $TOOL command not found" >&2
    exit 1
fi

case "$TOOL" in
    claude)
        printf '%s\n' "$changelog_block" | CLAUDECODE= claude -p --model haiku "$prompt"
        ;;
    codex)
        printf '%s\n' "$changelog_block" | codex exec --sandbox read-only "$prompt"
        ;;
    *)
        usage
        ;;
esac
