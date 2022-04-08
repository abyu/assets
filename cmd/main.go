package main

import (
	"github.com/abyu/assets/internal/config"
)

func main() {

	application, err := config.NewApplication(config.ApplicationContext{Port: 8080})
	if err != nil {
		panic(err)
	}

	err = application.ListenAndServe()
	if err != nil {
		panic(err)
	}
}
