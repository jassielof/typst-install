<script lang="ts">
  import { Copy, Check } from 'lucide-svelte';

  const REPO_URL = 'https://github.com/jassielof/typst-install';
  const PAGE_URL = 'https://jassielof.github.io/typst-install';
  const POSIX_URL = `${PAGE_URL}/install.sh`;
  const WINDOWS_URL = `${PAGE_URL}/install.ps1`;
  const POSIX_COMMAND = `curl -fsSL ${POSIX_URL} | bash`;
  const WINDOWS_COMMAND = `irm ${WINDOWS_URL} | iex`;

  let os = $state<'posix' | 'windows'>('posix');
  let copiedCommand = $state<string | null>(null);

  $effect(() => {
    if (navigator.userAgent.includes('Win')) {
      os = 'windows';
    }
  });

  function copyCommand(command: string) {
    navigator.clipboard.writeText(command).then(() => {
      copiedCommand = command;
      setTimeout(() => {
        copiedCommand = null;
      }, 2000);
    });
  }
</script>

<div class="flex min-h-screen flex-col items-center justify-center bg-base-200 p-4">
  <div class="w-full max-w-md text-center">
    <h1 class="text-5xl font-bold md:text-7xl">Typst</h1>
    <p class="text-base-content/70 py-6 text-lg md:text-xl">
      The installer for the modern, scriptable typesetting system.
    </p>

    <div role="tablist" class="tabs tabs-box justify-center">
      <button
        role="tab"
        class="tab"
        class:tab-active={os === 'posix'}
        onclick={() => (os = 'posix')}
      >
        macOS / Linux
      </button>
      <button
        role="tab"
        class="tab"
        class:tab-active={os === 'windows'}
        onclick={() => (os = 'windows')}
      >
        Windows
      </button>
    </div>

    <div class="mt-4">
      {#if os === 'posix'}
        <div class="relative">
          <div class="mockup-code text-left">
            <pre data-prefix="$"><code>{POSIX_COMMAND}</code></pre>
          </div>
          <button
            class="btn btn-ghost btn-sm absolute right-1 top-1"
            onclick={() => copyCommand(POSIX_COMMAND)}
            aria-label="Copy POSIX command"
          >
            {#if copiedCommand === POSIX_COMMAND}
              <Check class="h-4 w-4" />
            {:else}
              <Copy class="h-4 w-4" />
            {/if}
          </button>
        </div>
      {:else if os === 'windows'}
        <div class="relative">
          <div class="mockup-code text-left">
            <pre data-prefix=">"><code>{WINDOWS_COMMAND}</code></pre>
          </div>
          <button
            class="btn btn-ghost btn-sm absolute right-1 top-1"
            onclick={() => copyCommand(WINDOWS_COMMAND)}
            aria-label="Copy Windows command"
          >
            {#if copiedCommand === WINDOWS_COMMAND}
              <Check class="h-4 w-4" />
            {:else}
              <Copy class="h-4 w-4" />
            {/if}
          </button>
        </div>
      {/if}
    </div>

    <div class="text-base-content/50 mt-8">
      <p>
        Need help? Visit the
        <a href={REPO_URL} target="_blank" rel="noopener noreferrer" class="link">
          GitHub repository and file an issue.
        </a>.
      </p>
      <p class="mt-2 text-sm">This is an unofficial installer.</p>
    </div>
  </div>
</div>
