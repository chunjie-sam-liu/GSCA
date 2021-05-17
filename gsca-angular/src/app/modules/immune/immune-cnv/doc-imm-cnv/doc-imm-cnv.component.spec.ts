import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmCnvComponent } from './doc-imm-cnv.component';

describe('DocImmCnvComponent', () => {
  let component: DocImmCnvComponent;
  let fixture: ComponentFixture<DocImmCnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmCnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmCnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
