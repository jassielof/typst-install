<script lang="ts">
  import { onMount } from 'svelte';
  import { Copy, Check } from 'lucide-svelte';
  import { browser } from '$app/environment';

  const REPO_URL = 'https://github.com/jassielof/typst-install';
  const PAGE_URL = 'https://jassielof.github.io/typst-install';
  const POSIX_URL = `${PAGE_URL}/install.sh`;
  const WINDOWS_URL = `${PAGE_URL}/install.ps1`;
  const POSIX_COMMAND = `curl -fsSL ${POSIX_URL} | bash`;
  const WINDOWS_COMMAND = `irm ${WINDOWS_URL} | iex`;

  let os: 'posix' | 'windows' = $state('posix');
  let copiedCommand: string | null = $state(null);
  let mounted = $state(false);

  onMount(() => {
    if (browser && navigator.userAgent.toLowerCase().includes('win')) {
      os = 'windows';
    }
    mounted = true;
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

<div class="bg-base-200 flex min-h-screen flex-col items-center justify-center p-4">
  <div class="w-full max-w-md text-center md:max-w-2xl">
    <h1 class="font-[Buenard] text-5xl font-bold md:text-7xl">typst installer</h1>
    <p class="text-base-content/70 py-6 text-lg italic md:text-xl">
      For the modern, scriptable typesetting system.
    </p>

    <div role="tablist" class="tabs tabs-border justify-center" class:opacity-0={!mounted}>
      <button
        role="tab"
        class={{ tab: true, 'tab-active': os === 'posix' }}
        onclick={() => (os = 'posix')}
      >
        macOS / Linux
      </button>
      <button
        role="tab"
        class={{ tab: true, 'tab-active': os === 'windows' }}
        onclick={() => (os = 'windows')}
      >
        Windows
      </button>
    </div>

    <div class="mt-4" class:opacity-0={!mounted}>
      {#if os === 'posix'}
        <div class="relative">
          <div class="mockup-code text-left">
            <pre data-prefix="$"><code>{POSIX_COMMAND}</code></pre>
          </div>
          <button
            class="btn btn-neutral btn-sm absolute top-1 right-1 opacity-70 hover:opacity-100"
            onclick={() => copyCommand(POSIX_COMMAND)}
            aria-label="Copy POSIX command"
          >
            {#if copiedCommand === POSIX_COMMAND}
              <Check class="size-4" />
            {:else}
              <Copy class="size-4" />
            {/if}
          </button>
        </div>
      {:else if os === 'windows'}
        <div class="relative">
          <div class="mockup-code text-left">
            <pre data-prefix=">"><code>{WINDOWS_COMMAND}</code></pre>
          </div>
          <button
            class="btn btn-neutral btn-sm absolute top-1 right-1 opacity-70 hover:opacity-100"
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
          GitHub repository and file an issue
        </a>.
      </p>
      <p class="mt-2 text-sm font-bold">This is an unofficial installer.</p>
    </div>
  </div>
</div>

<style>
  .opacity-0 {
    opacity: 0;
  }

  /* Smooth fade-in when mounted */
  div[role='tablist'],
  .mt-4 {
    transition: opacity 200ms ease-in;
  }
</style>
