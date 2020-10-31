import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MutationRoutingModule } from './mutation-routing.module';
import { MutationComponent } from './mutation.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';

@NgModule({
  declarations: [MutationComponent, SearchBoxComponent],
  imports: [CommonModule, MutationRoutingModule, SharedModule],
})
export class MutationModule {}
