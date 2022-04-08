package config

import (
	"fmt"
	"github.com/abyu/assets/internal/log"
	"github.com/gorilla/mux"
	"net/http"
)
var logger = log.GetLogger()
type ApplicationContext struct {
	Port int
}

type Application struct {
	Context ApplicationContext
}
type SwaggerHandler interface {
	ConfigureRouter()
}

func NewApplication(ctx ApplicationContext) (Application, error) {
	return Application{ctx}, nil
}
func Alive() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Hello, World!"))
	}
}

func (a Application) setupSwaggerRoutes() error {

}

func (a Application) ListenAndServe() error {
	router := mux.NewRouter()
	router.Handle("/", Alive())
	logger.Infof("Starting application on port %d", a.Context.Port)
	return http.ListenAndServe(fmt.Sprintf(":%d", a.Context.Port), router)
}