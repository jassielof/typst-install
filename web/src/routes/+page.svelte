<script lang="ts">
  const POSIX_URL = 'https://typst.community/typst-install/install.sh';
  const WINDOWS_URL = 'https://typst.community/typst-install/install.ps1';
  const POSIX_COMMAND = `curl -fsSL ${POSIX_URL} | bash`;
  const WINDOWS_COMMAND = `irm ${WINDOWS_URL} | iex`;
  const REPO_URL = 'https://github.com/jassielof/typst-install';

  let os: 'posix' | 'windows' = 'posix';

  function copyCommand(command: string, btn: HTMLButtonElement) {
    navigator.clipboard.writeText(command).then(() => {
      const original = btn.textContent;
      btn.textContent = 'Copied!';
      setTimeout(() => {
        btn.textContent = original;
      }, 2000);
    });
  }
</script>

<main class="flex min-h-screen flex-col items-center justify-center p-4 text-center">
  <div class="max-w-2xl">
    <h1 class="text-5xl font-bold md:text-7xl">Typst</h1>
    <p class="text-base-content/70 py-6 text-lg md:text-xl">
      The installer for the modern, scriptable typesetting system.
    </p>

    <div class="tabs tabs-boxed justify-center" id="os-tabs">
      <button
        type="button"
        class="tab {os === 'posix' ? 'tab-active' : ''}"
        on:click={() => (os = 'posix')}
        data-os="posix">macOS / Linux</button
      >
      <button
        type="button"
        class="tab {os === 'windows' ? 'tab-active' : ''}"
        on:click={() => (os = 'windows')}
        data-os="windows">Windows</button
      >
    </div>

    <div id="command-container" class="mt-4">
      {#if os === 'posix'}
        <div id="posix-command" class="mockup-code text-left">
          <pre data-prefix="$"><code>{POSIX_COMMAND}</code></pre>
          <button
            class="btn btn-ghost btn-sm copy-btn"
            on:click={(e) => copyCommand(POSIX_COMMAND, e.currentTarget)}
          >
            Copy
          </button>
        </div>
      {:else}
        <div id="windows-command" class="mockup-code text-left">
          <pre data-prefix=">"><code>{WINDOWS_COMMAND}</code></pre>
          <button
            class="btn btn-ghost btn-sm copy-btn"
            on:click={(e) => copyCommand(WINDOWS_COMMAND, e.currentTarget)}
          >
            Copy
          </button>
        </div>
      {/if}
    </div>

    <div class="text-base-content/50 mt-8">
      <p>
        Need help? Visit the
        <a href={REPO_URL} target="_blank" rel="noopener noreferrer" class="link"
          >Typst GitHub repository</a
        >.
      </p>
    </div>
  </div>
</main>
