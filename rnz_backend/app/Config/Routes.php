<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// Home redirects to admin login
$routes->get('/', 'Admin\AuthController::login');

// Admin Public Auth
$routes->get('admin/login', 'Admin\AuthController::login');
$routes->post('admin/login', 'Admin\AuthController::processLogin');
$routes->get('admin/logout', 'Admin\AuthController::logout');

// Admin Protected Area
$routes->group('admin', ['filter' => 'adminAuth'], function ($routes) {
    $routes->get('dashboard', 'Admin\DashboardController::index');

    // Categories
    $routes->get('categories', 'Admin\CategoryController::index');
    $routes->post('categories', 'Admin\CategoryController::store');
    $routes->post('categories/update/(:num)', 'Admin\CategoryController::update/$1');
    $routes->get('categories/delete/(:num)', 'Admin\CategoryController::delete/$1');

    // Products
    $routes->get('products', 'Admin\ProductController::index');
    $routes->get('products/create', 'Admin\ProductController::create');
    $routes->post('products/store', 'Admin\ProductController::store');
    $routes->get('products/edit/(:num)', 'Admin\ProductController::edit/$1');
    $routes->post('products/update/(:num)', 'Admin\ProductController::update/$1');
    $routes->get('products/delete/(:num)', 'Admin\ProductController::delete/$1');
    $routes->get('products/delete-image/(:num)', 'Admin\ProductController::deleteImage/$1');

    // Orders & Verifications
    $routes->get('orders', 'Admin\OrderController::index');
    $routes->get('orders/(:num)', 'Admin\OrderController::show/$1');
    $routes->post('orders/(:num)/approve', 'Admin\OrderController::approvePayment/$1');
    $routes->post('orders/(:num)/reject', 'Admin\OrderController::rejectPayment/$1');
    $routes->post('orders/(:num)/ship', 'Admin\OrderController::submitShipment/$1');

    // Stock
    $routes->get('stock', 'Admin\StockController::index');
    $routes->post('stock/adjust', 'Admin\StockController::adjust');

    // Reports
    $routes->get('reports', 'Admin\ReportController::index');
    $routes->get('reports/export-pdf', 'Admin\ReportController::exportPdf');

    // Settings
    $routes->get('settings', 'Admin\SettingController::index');
    $routes->post('settings/payment-method', 'Admin\SettingController::storePaymentMethod');
    $routes->post('settings/payment-method/update/(:num)', 'Admin\SettingController::updatePaymentMethod/$1');
    $routes->get('settings/payment-method/delete/(:num)', 'Admin\SettingController::deletePaymentMethod/$1');
    $routes->post('settings/shipping-rate', 'Admin\SettingController::storeShippingRate');
    $routes->post('settings/shipping-rate/update/(:num)', 'Admin\SettingController::updateShippingRate/$1');
    $routes->get('settings/shipping-rate/delete/(:num)', 'Admin\SettingController::deleteShippingRate/$1');
});
