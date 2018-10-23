package main

import (
	"github.com/flowcommerce/tools/executor"
)

func main() {
	executor := executor.Create("active_merchant")

	executor = executor.Add("rm -f ./flowcommerce-*.gem")
	executor = executor.Add("git fetch --tags origin")
	// executor = executor.Add("script/set_version.rb")
	executor = executor.Add("dev tag")
	executor = executor.Add("sudo gem install --no-ri --no-rdoc flowcommerce-reference")
	executor = executor.Add("sudo gem install --no-ri --no-rdoc flowcommerce")
	executor = executor.Add("sudo gem install --no-ri --no-rdoc activemerchant")
	executor = executor.Add("gem build flowcommerce-activemerchant.gemspec")
	executor = executor.Add("gem push ./flowcommerce-*.gem")
	executor = executor.Add("rm -f ./flowcommerce-*.gem")

	executor.Run()
}
