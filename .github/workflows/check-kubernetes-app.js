const axios = require('axios');

async function checkWebAppStatus() {
  const url = 'http://app-silvestrini.skynet.com.br/';
  try {
    const response = await axios.get(url);
    if (response.status === 200) {
      console.log('A Web App está online e funcionando corretamente.');
    } else {
      throw new Error(`A Web App retornou um código de status inesperado: ${response.status}`);
    }
  } catch (error) {
    console.error(`Houve um problema ao verificar o status da Web App: ${error.message}`);
    process.exit(1);
  }
}

checkWebAppStatus();
