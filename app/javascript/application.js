// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"

// Função global para fechar alerts - pode ser chamada via onclick inline
window.closeAlert = function(button) {
  const alert = button.closest('.alert, .alert-dismissible, [data-alert-dismissible="true"]')
  if (alert) {
    alert.style.transition = 'opacity 0.15s linear'
    alert.style.opacity = '0'
    setTimeout(() => {
      alert.remove()
    }, 150)
  }
  return false
}

// Função global para toggle dropdown - pode ser chamada via onclick inline
window.toggleDropdown = function(button) {
  const dropdown = button.closest('.dropdown')
  if (!dropdown) return false
  
  const menu = dropdown.querySelector('.dropdown-menu')
  if (!menu) return false
  
  const isOpen = menu.classList.contains('show')
  
  // Fecha outros dropdowns
  document.querySelectorAll('.dropdown-menu.show').forEach(m => {
    if (m !== menu) {
      m.classList.remove('show')
      const toggle = m.closest('.dropdown')?.querySelector('[data-bs-toggle]')
      if (toggle) toggle.setAttribute('aria-expanded', 'false')
    }
  })
  
  // Toggle do dropdown atual
  if (isOpen) {
    menu.classList.remove('show')
    button.setAttribute('aria-expanded', 'false')
  } else {
    menu.classList.add('show')
    button.setAttribute('aria-expanded', 'true')
  }
  
  return false
}

// Função para obter o Bootstrap de diferentes formas
function getBootstrap() {
  // Tenta diferentes formas de acessar o Bootstrap
  if (window.bootstrap) {
    return window.bootstrap
  }
  if (typeof bootstrap !== 'undefined') {
    return bootstrap
  }
  // Tenta acessar via módulo importado
  if (window.bootstrapModule) {
    return window.bootstrapModule
  }
  return null
}

// Função para inicializar componentes do Bootstrap após o Turbo carregar
function initializeBootstrap() {
  const Bootstrap = getBootstrap()
  
  if (!Bootstrap) {
    // Aguarda Bootstrap carregar
    setTimeout(initializeBootstrap, 100)
    return
  }
  
  // Inicializa todos os dropdowns
  document.querySelectorAll('[data-bs-toggle="dropdown"]').forEach(element => {
    try {
      // Remove instância anterior se existir
      const instance = Bootstrap.Dropdown.getInstance(element)
      if (instance) {
        instance.dispose()
      }
      // Cria nova instância
      new Bootstrap.Dropdown(element)
    } catch (error) {
      console.error('Erro ao inicializar dropdown:', error)
      // Fallback: adiciona listener manual
      addManualDropdownListener(element)
    }
  })
  
  // Inicializa alerts dismissíveis
  initializeAlerts()
}

// Função para inicializar alerts do Bootstrap
function initializeAlerts() {
  const Bootstrap = getBootstrap()
  
  // Inicializa alerts via Bootstrap se disponível
  if (Bootstrap) {
    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      try {
        // Bootstrap já inicializa automaticamente com data-bs-dismiss, mas garantimos
        const alertInstance = Bootstrap.Alert.getInstance(alert)
        if (!alertInstance) {
          new Bootstrap.Alert(alert)
        }
      } catch (error) {
        // Fallback manual
        addManualAlertListener(alert)
      }
    })
  } else {
    // Se Bootstrap não estiver disponível, usa fallback manual
    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      addManualAlertListener(alert)
    })
  }
}

// Fallback manual para fechar alerts
function addManualAlertListener(alert) {
  const closeButton = alert.querySelector('.btn-close')
  if (!closeButton) return
  
  // Remove listeners anteriores para evitar duplicação
  const newButton = closeButton.cloneNode(true)
  closeButton.parentNode.replaceChild(newButton, closeButton)
  
  newButton.addEventListener('click', function(e) {
    e.preventDefault()
    e.stopPropagation()
    
    const alertElement = this.closest('.alert')
    if (!alertElement) return
    
    // Adiciona classe fade-out
    alertElement.classList.add('fade')
    alertElement.classList.remove('show')
    
    // Remove o elemento após animação
    setTimeout(() => {
      alertElement.remove()
    }, 150)
  }, true) // usa capture phase
}

// Fallback manual para dropdown se Bootstrap não funcionar
function addManualDropdownListener(element) {
  // Verifica se já tem listener manual
  if (element.dataset.manualDropdown === 'true') {
    return
  }
  element.dataset.manualDropdown = 'true'
  
  // Encontra o menu dropdown (pode ser próximo elemento ou dentro do parent)
  let dropdownMenu = element.nextElementSibling
  if (!dropdownMenu || !dropdownMenu.classList.contains('dropdown-menu')) {
    const dropdown = element.closest('.dropdown')
    if (dropdown) {
      dropdownMenu = dropdown.querySelector('.dropdown-menu')
    }
  }
  
  if (!dropdownMenu) {
    console.warn('Dropdown menu não encontrado para:', element)
    return
  }
  
  element.addEventListener('click', function(e) {
    e.preventDefault()
    e.stopPropagation()
    
    const isOpen = dropdownMenu.classList.contains('show')
    
    // Fecha outros dropdowns
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      if (menu !== dropdownMenu) {
        menu.classList.remove('show')
        const toggle = menu.previousElementSibling || 
          menu.closest('.dropdown')?.querySelector('[data-bs-toggle="dropdown"]')
        if (toggle) {
          toggle.setAttribute('aria-expanded', 'false')
        }
      }
    })
    
    // Toggle do dropdown atual
    if (isOpen) {
      dropdownMenu.classList.remove('show')
      element.setAttribute('aria-expanded', 'false')
    } else {
      dropdownMenu.classList.add('show')
      element.setAttribute('aria-expanded', 'true')
    }
  }, true) // usa capture phase para garantir que seja executado
  
  // Fecha dropdown ao clicar fora
  const clickOutsideHandler = function(e) {
    if (!element.contains(e.target) && !dropdownMenu.contains(e.target)) {
      dropdownMenu.classList.remove('show')
      element.setAttribute('aria-expanded', 'false')
    }
  }
  
  document.addEventListener('click', clickOutsideHandler, true)
}

// Inicializa após o Turbo carregar (importante para SPA)
document.addEventListener("turbo:load", initializeBootstrap)

// Inicializa no carregamento inicial
if (document.readyState === 'loading') {
  document.addEventListener("DOMContentLoaded", initializeBootstrap)
} else {
  initializeBootstrap()
}

// Adiciona fallback manual sempre (garante funcionamento)
document.addEventListener("turbo:load", () => {
  setTimeout(() => {
    document.querySelectorAll('[data-bs-toggle="dropdown"]').forEach(element => {
      const Bootstrap = getBootstrap()
      // Se Bootstrap não estiver disponível ou não tiver instância, usa fallback manual
      if (!Bootstrap) {
        addManualDropdownListener(element)
      } else {
        try {
          const instance = Bootstrap.Dropdown.getInstance(element)
          if (!instance) {
            addManualDropdownListener(element)
          }
        } catch (error) {
          addManualDropdownListener(element)
        }
      }
    })
  }, 300)
})

// Também aplica no carregamento inicial
setTimeout(() => {
  document.querySelectorAll('[data-bs-toggle="dropdown"]').forEach(element => {
    const Bootstrap = getBootstrap()
    if (!Bootstrap) {
      addManualDropdownListener(element)
    } else {
      try {
        const instance = Bootstrap.Dropdown.getInstance(element)
        if (!instance) {
          addManualDropdownListener(element)
        }
      } catch (error) {
        addManualDropdownListener(element)
      }
    }
  })
  
  // Inicializa alerts também
  initializeAlerts()
}, 300)

// Event delegation para dropdowns - funciona sempre, independente de quando o elemento é criado
document.addEventListener('click', function(e) {
  // Verifica se o clique foi em um elemento com data-bs-toggle="dropdown" ou no botão do dropdown
  const dropdownToggle = e.target.closest('[data-bs-toggle="dropdown"]') || 
                         (e.target.closest('.dropdown-toggle') && e.target.closest('.dropdown')?.querySelector('[data-bs-toggle="dropdown"]'))
  
  if (dropdownToggle) {
    e.preventDefault()
    e.stopPropagation()
    
    const dropdown = dropdownToggle.closest('.dropdown')
    if (!dropdown) return
    
    const dropdownMenu = dropdown.querySelector('.dropdown-menu')
    if (!dropdownMenu) return
    
    const isOpen = dropdownMenu.classList.contains('show')
    
    // Fecha outros dropdowns
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      if (menu !== dropdownMenu) {
        menu.classList.remove('show')
        const toggle = menu.closest('.dropdown')?.querySelector('[data-bs-toggle="dropdown"]')
        if (toggle) {
          toggle.setAttribute('aria-expanded', 'false')
        }
      }
    })
    
    // Toggle do dropdown atual
    if (isOpen) {
      dropdownMenu.classList.remove('show')
      dropdownToggle.setAttribute('aria-expanded', 'false')
    } else {
      dropdownMenu.classList.add('show')
      dropdownToggle.setAttribute('aria-expanded', 'true')
    }
    
    return false
  }
  
  // Fecha dropdowns ao clicar fora
  const clickedDropdown = e.target.closest('.dropdown')
  if (!clickedDropdown) {
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      menu.classList.remove('show')
      const toggle = menu.closest('.dropdown')?.querySelector('[data-bs-toggle="dropdown"]')
      if (toggle) {
        toggle.setAttribute('aria-expanded', 'false')
      }
    })
  }
}, true) // capture phase

// Event delegation para fechar alerts - funciona sempre, independente de quando o elemento é criado
document.addEventListener('click', function(e) {
  // Verifica se o clique foi em um botão de fechar alert
  const closeButton = e.target.classList.contains('btn-close') ? e.target : e.target.closest('.btn-close')
  
  if (closeButton) {
    const alert = closeButton.closest('.alert-dismissible, [data-alert-dismissible="true"]')
    
    if (alert) {
      e.preventDefault()
      e.stopPropagation()
      e.stopImmediatePropagation()
      
      // Fecha o alert imediatamente
      alert.style.transition = 'opacity 0.15s linear'
      alert.style.opacity = '0'
      
      setTimeout(() => {
        alert.remove()
      }, 150)
      
      return false
    }
  }
}, true) // capture phase - executa ANTES de qualquer outro handler

// Previne duplicação do nome do usuário e avatar no navbar
document.addEventListener("turbo:load", () => {
  // Garante que há apenas um nome visível no dropdown
  const dropdownToggle = document.querySelector('#navbarDropdown')
  if (dropdownToggle) {
    const namesInButton = dropdownToggle.querySelectorAll('.navbar-user-name')
    if (namesInButton.length > 1) {
      // Mantém apenas o primeiro e remove os outros
      for (let i = 1; i < namesInButton.length; i++) {
        namesInButton[i].remove()
      }
    }
    
    // Garante que há apenas um avatar
    const avatarsInButton = dropdownToggle.querySelectorAll('.avatar-small, .avatar-placeholder')
    if (avatarsInButton.length > 1) {
      for (let i = 1; i < avatarsInButton.length; i++) {
        avatarsInButton[i].remove()
      }
    }
  }
  
  setTimeout(initializeAlerts, 100)
})

// Inicializa alerts no carregamento inicial
if (document.readyState === 'loading') {
  document.addEventListener("DOMContentLoaded", initializeAlerts)
} else {
  setTimeout(initializeAlerts, 100)
}
