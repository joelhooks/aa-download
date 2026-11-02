#!/usr/bin/env bash
# Hostile partner filenames must never yield an extension that reaches curl -o or `scp -O`.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Load only the function: sourcing aa-book would run its mirror probes.
fn=$(sed -n '/^safe_extension() {/,/^}/p' "$here/../bin/aa-book")
[[ -n "$fn" ]] || { echo "FAIL: safe_extension not found in bin/aa-book"; exit 1; }
eval "$fn"
set +e
fail=0
ok()  { local got; got=$(safe_extension "$1"); [[ $? -eq 0 && "$got" == "$2" ]] || { echo "FAIL: '$1' -> '$got' (want $2)"; fail=1; }; }
bad() { local got; got=$(safe_extension "$1"); [[ $? -ne 0 && -z "$got" ]] || { echo "FAIL: accepted '$1' -> '$got'"; fail=1; }; }
ok "Designing Data -- Kleppmann.pdf" pdf
ok "book.EPUB" epub
ok "a.b.azw3" azw3
bad 'x.pdf;touch /tmp/pwned'
bad 'x.$(touch /tmp/pwned)'
bad 'x.`id`'
bad 'x.pdf /tmp/evil'
bad "x.pdf'"
bad 'x.p|df'
bad 'x.pdf/../../.ssh/authorized_keys'
bad 'x./etc/passwd'
bad 'noextension'
bad 'pdf'
bad 'x.'
bad 'x.sh'
bad $'x.pdf\nrm'
# The download path must use it: no other raw "${...##*.}" extension cut may exist in aa-book.
raw=$(grep -n '##\*\.}' "$here/../bin/aa-book" | grep -v '\${name##\*\.}')
[[ -z "$raw" ]] || { echo "FAIL: raw extension cut bypasses safe_extension: $raw"; fail=1; }
grep -q 'extension=$(safe_extension "$decoded_filename")' "$here/../bin/aa-book" || { echo "FAIL: download does not call safe_extension"; fail=1; }
[[ $fail -eq 0 ]] && echo "safe_extension: all cases pass"
exit $fail
