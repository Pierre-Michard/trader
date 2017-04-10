at_exit do
  if $PROGRAM_NAME.match?('bin/rails')
    p 'cancel all orders'
    PaymiumService.instance.cancel_all_orders
  end
end