at_exit do
  if $PROGRAM_NAME.match?('bin/rails')
    $exiting_rails=true
    sleep 1
    p 'cancel all orders'
    PaymiumService.instance.cancel_all_orders
  end
end