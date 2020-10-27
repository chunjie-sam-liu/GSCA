import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ExpressionRoutingModule } from './expression-routing.module';
import { ExpressionComponent } from './expression.component';
import { SearchBoxComponent } from './search-box/search-box.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [ExpressionComponent, SearchBoxComponent],
  imports: [CommonModule, ExpressionRoutingModule, SharedModule],
})
export class ExpressionModule {}
