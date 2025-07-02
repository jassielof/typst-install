const tabs = document.querySelectorAll("#os-tabs .tab");
const posixCommand = document.getElementById("posix-command");
const windowsCommand = document.getElementById("windows-command");

tabs.forEach((tab) => {
  tab.addEventListener("click", (e) => {
    e.preventDefault();
    tabs.forEach((t) => t.classList.remove("tab-active"));
    tab.classList.add("tab-active");

    const os = tab.getAttribute("data-os");
    if (os === "windows") {
      posixCommand.classList.add("hidden");
      windowsCommand.classList.remove("hidden");
    } else {
      windowsCommand.classList.add("hidden");
      posixCommand.classList.remove("hidden");
    }
  });
});

function copyCommand(elementId) {
  const commandEl = document.querySelector(`#${elementId} code`);
  const textToCopy = commandEl.innerText;
  navigator.clipboard.writeText(textToCopy).then(() => {
    const button = document.querySelector(`#${elementId} .copy-btn`);
    const originalText = button.innerText;
    button.innerText = "Copied!";
    setTimeout(() => {
      button.innerText = originalText;
    }, 2000);
  });
}
