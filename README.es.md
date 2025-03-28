# Crypto Raffles

## Descripción
Bienvenido a Crypto Raffles, una plataforma descentralizada para sorteos implementada sobre la blockchain de [Internet Computer](https://internetcomputer.org/).

Crypto Raffles permite la creación, gestión y participación en sorteos de manera completamente descentralizada, asegurando un proceso transparente y justo mediante la tecnología blockchain.

## Características Principales

- **Creación de Sorteos**: Los usuarios pueden crear nuevos sorteos especificando fecha de sorteo, precio de tickets, cantidad máxima de tickets y premios.
- **Compra de Tickets**: Participantes pueden comprar tickets específicos o aleatorios, por unidad o en paquetes.
- **Validación de Disponibilidad**: Verificación automática de la disponibilidad de tickets.
- **Realización de Sorteos**: Proceso aleatorio y verificable para la selección de ganadores. Solamente el creador del sorteo, autenticado, puede requerir la realización del sorteo.
- **Transparencia Total**: Toda la información sobre tickets comprados, ganadores y premios es pública y verificable.
- **Autenticación Segura**: Implementación de [Internet Identity](https://identity.ic0.app/) para garantizar una autenticación segura, privada y descentralizada.

## Tecnologías Utilizadas

- **Motoko**: Lenguaje de programación nativo de Internet Computer.
- **Internet Computer Protocol (ICP)**: Blockchain descentralizada que aloja el proyecto.
- **DFINITY Canister SDK**: Herramientas para el desarrollo y despliegue en ICP.

## Estados de un Sorteo

1. **Open**: Abierto para la compra de tickets.
2. **Closed**: Cerrado para compras (todos los tickets vendidos).
3. **Drawn**: Sorteo realizado y ganadores seleccionados.

## Funcionalidades Técnicas

- Generación segura de números aleatorios para selección de ganadores.
- Manejo de múltiples tokens para pagos (ICP, BTC, ETH).
- Sistema de almacenamiento eficiente para tickets disponibles y vendidos.
- Mecanismos para evitar compras duplicadas y validar argumentos.
- Estadísticas globales del sistema (total de sorteos, tickets vendidos, premios otorgados).

## Cómo Desplegar

### Requisitos Previos
- [DFINITY Canister SDK (dfx)](https://sdk.dfinity.org/docs/quickstart/local-quickstart.html)
- Node.js y curl
- Gestor de paquetes [Mops](https://mops.one/)

### Pasos para Despliegue Local

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/c-mena/crypto-raffles
   cd crypto-raffles
   ```

2. Instalar dependencias:
   - Instalar IC SDK ([instrucciones de instalación](https://internetcomputer.org/docs/building-apps/getting-started/install))
   - Instalar Mops CLI:
     ```bash
     # Con curl
     curl -fsSL cli.mops.one/install.sh | sh
     # O con npm
     npm i -g ic-mops
     ```
   - Inicializar e instalar dependencias del proyecto:
     ```bash
     mops init
     mops install
     ```

3. Iniciar el replica local de Internet Computer:
   ```bash
   dfx start --background
   ```

4. Desplegar los canisters:
   ```bash
   dfx deploy
   ```

### Despliegue en Mainnet

1. Asegúrese de tener ciclos suficientes en su cuenta:
   ```bash
   dfx identity get-principal
   dfx ledger balance
   ```

2. Despliegue en la red principal:
   ```bash
   dfx deploy --network ic
   ```

## Uso del Backend

El backend expone múltiples funciones para interactuar con los sorteos:

- `status`: Resumen de todos los sorteos
- `createRaffle`: Crear un nuevo sorteo
- `raffleSetup`: Consultar la configuración de un sorteo
- `raffleSummary`: Resumen de un sorteo
- `raffleBuySelectedTickets`: Comprar boletos específicos
- `raffleBuyRandomTickets`: Comprar boletos aleatorios
- `raffleMakeTheDraw`: Realizar el sorteo y seleccionar ganadores aleatoriamente
- `raffleWinners`: Consultar los ganadores de un sorteo
- `raffleStatus`: Consultar el estado de un sorteo
- `raffleAvailableTickets`: Consultar los boletos disponibles en un sorteo
- `rafflePurchasedTickets`: Consultar los boletos comprados en un sorteo
- `raffleFindBuyer`: Busca al comprador de un boleto en un sorteo
- `raffleFindTickets`: Busca los boletos comprados por una identidad en un sorteo
- ...

Al desplegar el proyecto, se generan automáticamente URLs para acceder a una interfaz básica de usuario Candid UI. Esta interfaz permite evaluar todas las funcionalidades del backend de manera interactiva, sin necesidad de un frontend personalizado. Cada función del backend puede ser probada directamente desde esta interfaz, facilitando las pruebas y verificación del funcionamiento del sistema.

## Desarrollo Futuro

- Interfaz de usuario web
- Integración con billeteras digitales
- Sistema de notificaciones para ganadores
- Smart contracts para distribución automática de premios

## Contribuciones

Las contribuciones son bienvenidas. Por favor, siga estos pasos:

1. Fork del repositorio
2. Cree una nueva rama (`git checkout -b feature/nueva-caracteristica`)
3. Haga commit de sus cambios (`git commit -am 'Añade nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Cree un nuevo Pull Request

---

*Este proyecto fue desarrollado como prueba de concepto en Motoko, mi primer programa en este lenguaje.* 😊