<template>
  <v-container fluid>
    <header>
      <breadcrumb style="margin-bottom: 20px" />
      <h1 v-show="!validForm" class="PageTitle">
        J'ai une question sur les méthodes de prospection
      </h1>
    </header>
    <section v-show="!validForm" class="FormSection">
      <div class="FormContent">
        <div v-if="alertMessage" class="Alert">
          <span class="AlertMessage">
            {{ alertMessage }}
          </span>
          <i
            class="v-icon mdi mdi-close-circle AlertCloseIcon"
            @click="deleteAlertMessage"
          ></i>
        </div>
        <label for="user-name">Nom</label>
        <input
          id="user-name"
          v-model="userName"
          type="text"
          placeholder="Henri Martin"
        />
        <label for="user-mail">Adresse email</label>
        <input
          id="user-mail"
          v-model="userMail"
          type="email"
          placeholder="henri.martin@monmail.fr"
        />
        <label>Méthode de prospection</label>
        <contact-form-select
          :z-index="5"
          default-message="EPOC, SHOC..."
          :items-list="protocolsList"
          @selectedItem="updateSelectedProtocol"
        />
        <label>Département</label>
        <contact-form-select
          :z-index="4"
          default-message="Département"
          :items-list="$departmentsList"
          @selectedItem="updateSelectedDepartment"
        />
        <label for="message">Message</label>
        <textarea id="message" v-model="userMessage" placeholder="Bonjour..." />
        <captcha-form
          :captcha-ref="captchaRef"
          @captchaUser="updateCaptchaUser"
        />
        <button
          :disabled="disabledButton"
          class="PrimaryButton"
          @click="validateForm"
        >
          Envoyer
        </button>
      </div>
    </section>
    <contact-form-confirmation v-show="validForm" />
  </v-container>
</template>

<script>
import Breadcrumb from '~/components/layouts/Breadcrumb.vue'
import ContactFormSelect from '~/components/about/ContactFormSelect.vue'
import CaptchaForm from '~/components/about/CaptchaForm.vue'
import ContactFormConfirmation from '~/components/about/ContactFormConfirmation.vue'

export default {
  components: {
    breadcrumb: Breadcrumb,
    'contact-form-select': ContactFormSelect,
    'captcha-form': CaptchaForm,
    'contact-form-confirmation': ContactFormConfirmation,
  },
  data: () => ({
    userName: '',
    userMail: '',
    selectedProtocol: null,
    selectedDepartment: null,
    userMessage: '',
    captchaRef: '',
    captchaUser: '',
    protocolsList: [
      'EPOC ODF',
      'EPOC',
      'STOC',
      'SHOC',
      'Observatoire Rapaces',
      'LIMAT',
      'Wetlands',
      'Listes complètes et données ponctuelles',
    ],
    emailConfigs: [
      'oiseauxdefrance',
      'oiseauxdefrance',
      'stoc',
      'shoc',
      'rapaces',
      'oiseauxdefrance',
      'wetlands',
      'oiseauxdefrance',
    ],
    emailConfig: '',
    alertMessage: null,
    validForm: false,
    disabledButton: false,
  }),
  mounted() {
    this.captchaRef = this.$generateCaptcha()
  },
  methods: {
    updateSelectedProtocol(protocol) {
      this.selectedProtocol = protocol[0]
      // console.log(this.selectedProtocol)
      this.emailConfig = this.emailConfigs[protocol[1]]
      // console.log(this.emailConfig)
    },
    updateSelectedDepartment(department) {
      this.selectedDepartment = department[0]
      // console.log(this.selectedDepartment)
    },
    updateCaptchaUser(captcha) {
      this.captchaUser = captcha
    },
    validateForm() {
      if (this.captchaUser !== this.captchaRef) {
        this.alertMessage =
          "Le code de sécurité que vous avez renseigné n'est pas bon"
      }
      if (!this.userMessage) {
        this.alertMessage = 'Veuillez écrire un message'
      }
      if (!this.selectedDepartment) {
        this.alertMessage = 'Veuillez sélectionner un département'
      }
      if (!this.selectedProtocol) {
        this.alertMessage = 'Veuillez sélectionner une méthode de prospection'
      }
      if (!this.$checkEmail(this.userMail)) {
        this.alertMessage = 'Veuillez renseigner une adresse email valide'
      }
      if (!this.userMail) {
        this.alertMessage = 'Veuillez renseigner votre adresse email'
      }
      if (!this.userName) {
        this.alertMessage = 'Veuillez renseigner votre nom'
      }
      if (
        this.userName &&
        this.$checkEmail(this.userMail) &&
        this.selectedProtocol &&
        this.selectedDepartment &&
        this.userMessage &&
        this.captchaUser === this.captchaRef
      ) {
        // this.validForm = true
        this.disabledButton = true
        this.alertMessage = null
        const messageIntroduction = `Nom : ${this.userName} \nEmail : ${this.userMail} \nDépartement : ${this.selectedDepartment} \n\nMessage : \n`
        this.$mail
          .send({
            config: this.emailConfig,
            subject: `[Atlas ODF] J'ai une question sur les méthodes de prospection (${this.selectedProtocol})`,
            text: messageIntroduction + this.userMessage,
          })
          .then((response) => {
            // console.log(response)
            this.validForm = true
          })
          .catch((error) => {
            this.alertMessage = "L'envoi du mail a échoué..."
            this.disabledButton = false
            if (error.response) {
              console.log(error.response.data)
            }
          })
      }
    },
    deleteAlertMessage() {
      this.alertMessage = null
    },
  },
  head() {
    return {
      title: this.$getPageTitle(this.$route.path),
    }
  },
}
</script>

<style scoped>
div.container.container--fluid {
  padding-top: 68px;
}

header {
  width: 100%;
  padding: 1.4% 16% 3% 16%;
  display: flex;
  flex-direction: column;
}

.PageTitle {
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: 600;
  font-size: 32px;
  line-height: 48px;
  color: #000;
  text-align: center;
}

.FormSection,
.ConfirmationSection {
  padding-bottom: 2%;
  display: flex;
}

.FormContent {
  margin: auto;
  display: flex;
  flex-direction: column;
}

.Alert {
  width: 626px;
  height: 32px;
  padding: 0 2%;
  margin-bottom: 16px;
  border: 1px solid #f44336;
  box-sizing: border-box;
  border-radius: 8px;
  color: #f44336;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.AlertMessage {
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: normal;
  font-size: 14px;
  line-height: 21px;
}

.AlertCloseIcon {
  cursor: pointer;
}

label {
  margin-bottom: 8px;
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: 500;
  font-size: 14px;
  line-height: 21px;
  color: #000;
}

input {
  width: 626px;
  height: 32px;
  margin-bottom: 16px;
  border: 1px solid rgba(38, 38, 38, 0.1);
  box-sizing: border-box;
  border-radius: 8px;
  outline: none;
  padding-left: 2%;
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: normal;
  font-size: 14px;
  line-height: 21px;
  color: #262626;
}

input:focus {
  border: 1px solid #eece25;
}

textarea {
  padding: 1.4% 2%;
  margin-bottom: 16px;
  border: 1px solid rgba(38, 38, 38, 0.1);
  box-sizing: border-box;
  border-radius: 8px;
  outline: none;
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: normal;
  font-size: 14px;
  line-height: 21px;
  color: #262626;
}

textarea:focus {
  border: 1px solid #eece25;
}

.ConfirmationContent {
  margin: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.ConfirmationPicture {
  width: 280px;
  margin-bottom: 30px;
}

.ConfirmationTitle {
  margin-bottom: 16px;
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: 600;
  font-size: 24px;
  line-height: 36px;
  color: #262626;
}

.ConfirmationSubtitle {
  margin-bottom: 30px;
  font-family: 'Poppins', sans-serif;
  font-style: normal;
  font-weight: normal;
  font-size: 14px;
  line-height: 21px;
  color: #262626;
}
</style>
