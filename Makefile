include .env

clean:
		@rm -rf dist
		@mkdir -p dist

build: clean
		@for dir in `ls handler`; do \
			GOOS=linux go build -o dist/handler/$$dir github.com/nathanmalishev/go-lambda-vpc-experiement/handler/$$dir; \
		done

gomon:
	reflex -r '\.go' -s -- sh -c 'make build && make run'

run:
		sam local start-api

install:
		go get github.com/aws/aws-lambda-go/events
		go get github.com/aws/aws-lambda-go/lambda
		go get github.com/stretchr/testify/assert
		go get github.com/aws/aws-xray-sdk-go/xray
		go get -u github.com/go-sql-driver/mysql

install-dev:
		go get github.com/awslabs/aws-sam-local

test:
		go test ./... --cover

configure:
		aws s3api create-bucket \
			--bucket $(AWS_BUCKET_NAME) \
			--region $(AWS_REGION) \
			--create-bucket-configuration LocationConstraint=$(AWS_REGION)

package: build
		@aws cloudformation package \
			--template-file template.yml \
			--s3-bucket $(AWS_BUCKET_NAME) \
			--region $(AWS_REGION) \
			--output-template-file package.yml

packageVPC:
		@aws cloudformation package \
			--template-file vpc_cloudformation_template.yml \
			--s3-bucket $(AWS_BUCKET_NAME) \
			--region $(AWS_REGION) \
			--output-template-file vpc_package.yml

buildVPC:
		@aws cloudformation deploy \
			--template-file vpc_package.yml \
			--region $(AWS_REGION) \
			--capabilities CAPABILITY_IAM \
			--parameter-overrides $(PARAMETER_OVERRIDES_VPC) \
			--stack-name $(AWS_STACK_NAME_VPC)

deploy:
		@aws cloudformation deploy \
			--template-file package.yml \
			--region $(AWS_REGION) \
			--capabilities CAPABILITY_IAM \
			--parameter-overrides $(PARAMETER_OVERRIDES) \
			--stack-name $(AWS_STACK_NAME)

describe:
		@aws cloudformation describe-stacks \
			--region $(AWS_REGION) \
			--stack-name $(AWS_STACK_NAME) \

outputs:
		@make describe | jq -r '.Stacks[0].Outputs'

url:
		@make describe | jq -r ".Stacks[0].Outputs[0].OutputValue" -j
