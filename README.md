* Sitio donde se almacenan las más recientes versiones de los paquetes de R del lab

En este repositorio se almacenan las versiones más recientes de los paquetes del [[https://biometriaforestal.uchile.cl][Laboratorio de Biometría y Modelación Forestal]], a cargo  del Profesor [[https://eljatib.com][Christian Salas-Eljatib]],  de la [[https://uchile.cl][Universidad de Chile]].

Si bien estos paquetes estan disponibles en el repositorio *CRAN* del software,
su actualización es algo más lenta de lo que vamos desarrollando por lo cual
es preferible Ud. siempre verifique las versiones de los paquetes instalados.

Para lo anterior, Ud. puede proceder como sigue, para lo cual se asume que ya tiene instalados los paquetes =biometrics= y =datana= en su versión de R. 

  
Llamarlos a la sesión:

  #+begin_src R
  library(biometrics)
  library(datana)
  #+end_src
y para verificar la versión del paquete, puede emplear la función =packageVersion()= como sigue
#+begin_src R
packageVersion("biometrics")
#+end_src

Cita del paquete
#+begin_src R
citation("biometrics")
#+end_src

** Sugerencias/errores
En caso de encontrar errores, tenga sugerencias, o dudas, por favor escribir a [[mailto:christian.salas@uchile.cl][este email]].

