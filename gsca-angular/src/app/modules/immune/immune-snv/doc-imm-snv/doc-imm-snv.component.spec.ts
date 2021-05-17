import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmSnvComponent } from './doc-imm-snv.component';

describe('DocImmSnvComponent', () => {
  let component: DocImmSnvComponent;
  let fixture: ComponentFixture<DocImmSnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmSnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmSnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
