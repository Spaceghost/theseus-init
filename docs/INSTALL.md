# Versioned installation and rollback

Keep the bootloader's existing Alpine entry and a console that
can select it. Use a bootloader that can select a specific
init executable in the installed root. A kernel or initramfs
that mounts the root must pass the selected executable to PID 1.

## Obtain a verified Linux bundle

For x86-64 Linux, use a successful release-bundle workflow run
for the exact commit you intend to boot. The archive contains
the static executables, build input versions, runtime license notices,\nand this guide.
Site configuration supplies the compiled graph.

~~~sh
repo=Spaceghost/theseus-init
commit=REVIEWED_FULL_COMMIT_SHA
name="theseus-init-linux-x86_64-$commit"
run=$(gh run list --repo "$repo" --workflow release-bundle.yml \
  --commit "$commit" --status success --limit 1 --json databaseId --jq '.[0].databaseId')
gh run download "$run" --repo "$repo" --name "$name"
gh attestation verify "$name.tar.gz" --repo "$repo" \
  --signer-workflow "$repo/.github/workflows/release-bundle.yml" \
  --source-ref refs/heads/main --source-digest "$commit"
~~~

After verification succeeds, extract the archive and add your
compiled graph.tsc beside its executables. The workflow artifacts
are available for 30 days. A fresh workflow run on main can
rebuild its current commit.

~~~sh
tar -xzf "$name.tar.gz"
cp /absolute/path/to/graph.tsc theseus-init/
install -d -m 0755 /opt/theseus/releases
./theseus-init/theseus-install /opt/theseus/releases "$commit" "$PWD/theseus-init"
~~~

## Build from source

1. Build src/install.nelua as theseus-install. Build src/init.nelua,
   src/supervisor.nelua, and src/live_client.nelua as theseus-init,
   theseusd, and theseus. Put the latter three and the compiled
   graph.tsc in an administrator-owned bundle directory. Compile
   the graph before installation and give it a target named default.
2. Publish the bundle from the system where it will boot. Use the
   release root shown below and a fresh release ID for every change
   to the binaries or graph.

   ~~~sh
   install -d -m 0755 /opt/theseus/releases
   ./theseus-install /opt/theseus/releases 2026.11.19.1 /path/to/bundle
   ~~~

   The installer copies the files into a private sibling directory,
   validates the compiled target, and publishes the complete directory
   under the release ID. It refuses to overwrite a published release.
   The target filesystem must support atomic rename with no replacement
   and directory sync. Run the installer on trusted local filesystems
   from verified build inputs. Use a new ID to stage a corrected bundle.
3. Add a boot entry selecting that release and keep your previous
   verified entry as the default. In GRUB give the menu entry an ID
   beginning with a letter, such as theseus-candidate. For a Linux
   bootloader with a root
   mount or a cooperating initramfs, use this command-line fragment.

   ~~~text
   init=/opt/theseus/releases/2026.11.19.1/theseus-init theseus.pid1=1
   ~~~

   On Alpine add theseus.openrc=1 for OpenRC. The init executable uses
   theseusd and graph.tsc from its own directory. The matching client
   and the symlink live there too. A release ID and its directory
   must remain stable while an entry refers to them. Select the\n   installed executable by its actual path.
4. Trial the candidate using the boot menu or a boot-once mechanism.
   Keep the console open, verify the target and real application
   readiness, and test a normal reboot. Only then select the candidate
   as the persistent default.
5. To roll back, boot the prior entry and restore it as the persistent
   default. To recover from a broken service graph, use the prior
   entry or boot with theseus.rescue=1. Keep filesystem and database
   backups and choose migrations compatible with the releases you
   expect to boot on the same system.

For a portable boot image, include the loader and libraries for the
target platform alongside the binaries' normal runtime dependencies.
Leave the release root under trusted administration and keep its
entries on the mounted root filesystem. A half-written staging
directory starts with a dot. It can be removed after verifying that
its installer is no longer running.
