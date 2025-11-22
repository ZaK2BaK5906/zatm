$(document).ready(function() {
    // Variables
    let hasLaptop = false;
    let hasC4 = false;
    let hasDrill = false;

    // Écouter les messages du client Lua
    window.addEventListener('message', function(event) {
        const data = event.data;

        switch(data.type) {
            case 'openUI':
                openUI(data);
                break;
        }
    });

    // Fonction pour ouvrir l'interface
    function openUI(data) {
        hasLaptop = data.hasLaptop;
        hasC4 = data.hasC4;
        hasDrill = data.hasDrill;

        // Mettre à jour les statuts et boutons
        updateOptionStatus('laptop', hasLaptop);
        updateOptionStatus('c4', hasC4);
        updateOptionStatus('drill', hasDrill);

        // Afficher l'interface avec animation
        $('#app').fadeIn(300);
    }

    // Fonction pour mettre à jour le statut d'une option
    function updateOptionStatus(method, hasItem) {
        const statusElement = $(`#${method}Status`);
        const btnElement = $(`#${method}Btn`);

        if (hasItem) {
            statusElement.removeClass('locked').addClass('available');
            statusElement.html(`
                <i class="fas fa-check-circle"></i>
                <span>Disponible</span>
            `);
            btnElement.prop('disabled', false);
        } else {
            statusElement.removeClass('available').addClass('locked');
            let itemName = '';

            switch(method) {
                case 'laptop':
                    itemName = 'Tablette requise';
                    break;
                case 'c4':
                    itemName = 'C4 requis';
                    break;
                case 'drill':
                    itemName = 'Perceuse requise';
                    break;
            }

            statusElement.html(`
                <i class="fas fa-lock"></i>
                <span>${itemName}</span>
            `);
            btnElement.prop('disabled', true);
        }
    }

    // Fonction pour fermer l'interface
    function closeUI() {
        $('#app').fadeOut(300);

        // Envoyer un message au client Lua
        $.post('https://zatm/closeUI', JSON.stringify({}));
    }

    // Fonction pour démarrer un braquage
    function startRobbery(method) {
        // Animation du bouton
        const btn = $(`#${method}Btn`);
        btn.html('<i class="fas fa-spinner fa-spin"></i><span>Démarrage...</span>');
        btn.prop('disabled', true);

        // Envoyer au client Lua
        $.post('https://zatm/startRobbery', JSON.stringify({
            method: method
        }));

        // Fermer l'interface après un court délai
        setTimeout(() => {
            closeUI();
        }, 500);
    }

    // Events handlers
    $('#closeBtn').click(function() {
        closeUI();
    });

    $('#laptopBtn').click(function() {
        if (!$(this).prop('disabled')) {
            startRobbery('laptop');
        }
    });

    $('#c4Btn').click(function() {
        if (!$(this).prop('disabled')) {
            startRobbery('c4');
        }
    });

    $('#drillBtn').click(function() {
        if (!$(this).prop('disabled')) {
            startRobbery('drill');
        }
    });

    // Fermer avec ESC
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            if ($('#app').is(':visible')) {
                closeUI();
            }
        }
    });

    // Effet hover sur les cartes
    $('.option-card').hover(
        function() {
            $(this).addClass('hover-effect');
        },
        function() {
            $(this).removeClass('hover-effect');
        }
    );

    // Animation des icônes au survol
    $('.option-icon').hover(
        function() {
            $(this).find('i').css('transform', 'rotate(360deg) scale(1.1)');
        },
        function() {
            $(this).find('i').css('transform', 'rotate(0deg) scale(1)');
        }
    );

    $('.option-icon i').css('transition', 'transform 0.5s ease');
});
